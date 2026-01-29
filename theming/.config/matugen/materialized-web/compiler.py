import fnmatch
import hashlib
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple


def _stable_hash_bytes(*parts: bytes) -> str:
    h = hashlib.sha256()
    for p in parts:
        h.update(p)
        h.update(b"\x00")
    return h.hexdigest()


def _read_json(path: Path) -> Dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _minify_css(css: str) -> str:
    # Not aggressive minification, just trims. Keeps output readable for debugging.
    lines = []
    for line in css.splitlines():
        s = line.strip()
        if s:
            lines.append(s)
    return "\n".join(lines) + "\n"


@dataclass
class SiteConfig:
    path: Path
    raw: Dict[str, Any]

    @property
    def matches(self) -> List[str]:
        m = self.raw.get("match", [])
        return m if isinstance(m, list) else [m]

    @property
    def rules(self) -> List[Dict[str, Any]]:
        r = self.raw.get("rules", [])
        return r if isinstance(r, list) else []

    def matches_url(self, url: str) -> bool:
        for pat in self.matches:
            if fnmatch.fnmatch(url, pat):
                return True
        return False


def load_scheme(scheme_path: Path) -> Tuple[Dict[str, str], bytes]:
    raw_bytes = scheme_path.read_bytes()
    raw = json.loads(raw_bytes.decode("utf-8"))
    # Normalize to str->str
    scheme: Dict[str, str] = {str(k): str(v) for k, v in raw.items()}
    return scheme, raw_bytes


def iter_site_configs(sites_dir: Path) -> List[SiteConfig]:
    out: List[SiteConfig] = []
    if not sites_dir.exists():
        return out
    for p in sorted(sites_dir.glob("*.json")):
        try:
            raw = _read_json(p)
            out.append(SiteConfig(path=p, raw=raw))
        except Exception:
            # ignore broken files in v0; you can surface errors later
            continue
    return out


def find_site_config(url: str, sites_dir: Path) -> Optional[SiteConfig]:
    for cfg in iter_site_configs(sites_dir):
        if cfg.matches_url(url):
            return cfg
    return None


def build_base_vars_css(scheme: Dict[str, str]) -> str:
    # Template: every scheme key becomes a css variable: --mat-<role>
    # Example: surface -> --mat-surface
    # Also adds a couple convenience vars if present.
    lines = [":root {"]
    for role, value in sorted(scheme.items()):
        var_name = "--mat-" + role.replace("_", "-")
        lines.append(f"  {var_name}: {value};")
    lines.append("}")
    return "\n".join(lines) + "\n"


def build_rules_css(rules: List[Dict[str, Any]]) -> str:
    blocks: List[str] = []
    for rule in rules:
        selector = rule.get("selector")
        props = rule.get("set", {})
        important = bool(rule.get("important", False))
        if not selector or not isinstance(props, dict):
            continue

        lines = [f"{selector} {{"]

        for prop, value in props.items():
            if value is None:
                continue
            prop_s = str(prop).strip()
            val_s = str(value).strip()
            if not prop_s or not val_s:
                continue
            bang = " !important" if important else ""
            lines.append(f"  {prop_s}: {val_s}{bang};")

        lines.append("}")
        blocks.append("\n".join(lines))

    return "\n\n".join(blocks) + ("\n" if blocks else "")


def compile_css_for_url(url: str, scheme_path: Path, sites_dir: Path) -> Tuple[str, str]:
    """
    Returns (css_text, etag_value_without_quotes)
    """
    scheme, scheme_bytes = load_scheme(scheme_path)
    site_cfg = find_site_config(url, sites_dir)

    base_css = build_base_vars_css(scheme)
    rules_css = ""
    site_bytes = b""
    site_id = "default"

    if site_cfg:
        site_bytes = site_cfg.path.read_bytes()
        site_id = site_cfg.path.name
        rules_css = build_rules_css(site_cfg.rules)

    # Put base vars first so site rules can reference them.
    css = _minify_css(base_css + "\n" + rules_css)

    etag = _stable_hash_bytes(
        b"v1",
        scheme_bytes,
        site_bytes,
        url.encode("utf-8"),
    )
    # If you prefer caching by site only (not per full URL), swap url for site_id.
    return css, etag

