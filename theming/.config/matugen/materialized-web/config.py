from dataclasses import dataclass
from pathlib import Path

@dataclass(frozen=True)
class Settings:
    scheme_path: Path = Path("scheme/current.json")
    sites_dir: Path = Path("sites")
    # If you only ever use userscripts with GM_xmlhttpRequest you can ignore CORS,
    # but enabling it for localhost is convenient.
    enable_cors: bool = True
    cors_allow_origin: str = "*"  # fine for localhost-only server

