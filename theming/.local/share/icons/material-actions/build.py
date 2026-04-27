#!/usr/bin/env python3
"""Build material-actions icon theme by downloading Material Symbols SVGs."""

import json
import shutil
import sys
from pathlib import Path
from urllib.request import urlopen
from urllib.error import HTTPError

THEME_DIR = Path(__file__).parent.resolve()
ACTIONS_DIR = THEME_DIR / "scalable" / "actions"
MAPPINGS_FILE = THEME_DIR / "mappings.json"

BASE_URL = (
    "https://raw.githubusercontent.com/google/material-design-icons/master"
    "/symbols/web/{name}/materialsymbolsrounded/{name}_24px.svg"
)


def download_icon(name: str) -> str | None:
    """Download a Material Symbols SVG. Returns SVG text or None if missing."""
    url = BASE_URL.format(name=name)
    try:
        with urlopen(url, timeout=30) as response:
            return response.read().decode("utf-8")
    except HTTPError as e:
        if e.code == 404:
            print(f"  WARNING: icon not found on GitHub: {name}")
        else:
            print(f"  WARNING: failed to download {name}: {e}")
        return None
    except Exception as e:
        print(f"  WARNING: error downloading {name}: {e}")
        return None


def main() -> int:
    ACTIONS_DIR.mkdir(parents=True, exist_ok=True)

    with MAPPINGS_FILE.open("r", encoding="utf-8") as f:
        mappings = json.load(f)

    # Collect unique material icons to download
    material_icons: dict[str, str] = {}  # name -> svg text
    needed = {entry["material"] for entry in mappings}

    print(f"Downloading {len(needed)} unique Material Symbols icons...")
    for name in sorted(needed):
        svg = download_icon(name)
        if svg is not None:
            material_icons[name] = svg

    print(f"Successfully downloaded {len(material_icons)}/{len(needed)} icons.")

    # Write freedesktop-named copies
    written = 0
    skipped = 0
    for entry in mappings:
        material_name = entry["material"]
        freedesktop_name = entry["freedesktop"]
        target = ACTIONS_DIR / f"{freedesktop_name}.svg"

        if material_name not in material_icons:
            skipped += 1
            continue

        target.write_text(material_icons[material_name], encoding="utf-8")
        written += 1

    print(f"Wrote {written} icon files to {ACTIONS_DIR}")
    if skipped:
        print(f"Skipped {skipped} mappings due to missing source icons")

    return 0


if __name__ == "__main__":
    sys.exit(main())
