#!/usr/bin/env -S uv run python3
"""
analyze_site.py — Extract CSS custom properties from a website for theming.

Usage:
    uv run tools/analyze_site.py <url> [-o output.json]

Example:
    uv run tools/analyze_site.py https://reddit.com -o /tmp/reddit.json
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from playwright.sync_api import sync_playwright


def categorize_var(name: str) -> str:
    """Categorize a CSS variable name by its naming pattern."""
    name_lower = name.lower()
    if re.search(r"\b(bg|background|surface|canvas|base)\b", name_lower):
        return "background"
    if (
        re.search(r"\b(fg|foreground|text|color|link|muted)\b", name_lower)
        and "border" not in name_lower
    ):
        return "foreground"
    if re.search(r"\b(border|outline|divider|separator|rule)\b", name_lower):
        return "border"
    if re.search(
        r"\b(button|btn|control|input|checkbox|radio|slider|track)\b", name_lower
    ):
        return "button"
    if re.search(r"\b(shadow|elevation|depth)\b", name_lower):
        return "shadow"
    if re.search(r"\b(focus|selection|highlight|caret|cursor|accent)\b", name_lower):
        return "accent"
    if re.search(r"\b(icon|svg|logo)\b", name_lower):
        return "icon"
    if re.search(
        r"\b(danger|error|warning|success|info|done|sponsors|severe)\b", name_lower
    ):
        return "semantic"
    return "other"


def extract_variables(page) -> dict[str, str]:
    """
    Extract all CSS custom properties from a page using multiple sources:
    1. getComputedStyle on documentElement (resolved values, cross-origin safe)
    2. Stylesheet cssRules (raw var()/color-mix() expressions)
    """
    result: dict[str, str] = {}

    script = """
    () => {
        const vars = {};

        // 1. getComputedStyle — resolved values, cross-origin sheets work
        const cs = getComputedStyle(document.documentElement);
        for (const prop of cs) {
            if (prop.startsWith('--')) {
                vars[prop] = cs.getPropertyValue(prop).trim();
            }
        }

        // 2. Same-origin stylesheet rules — raw var()/color-mix() expressions
        try {
            for (const sheet of document.styleSheets) {
                try {
                    for (const rule of sheet.cssRules) {
                        if (rule.style) {
                            for (const prop of rule.style) {
                                if (prop.startsWith('--')) {
                                    const val = rule.style.getPropertyValue(prop).trim();
                                    if (val && !vars[prop]) {
                                        vars[prop] = val;
                                    }
                                }
                            }
                        }
                        // Also capture custom properties in var() references
                        if (rule.cssText) {
                            const matches = rule.cssText.matchAll(/--[a-zA-Z0-9_-]+/g);
                            for (const m of matches) {
                                const prop = m[0];
                                if (!vars[prop]) {
                                    vars[prop] = '[unresolved]';
                                }
                            }
                        }
                    }
                } catch (e) {
                    // Cross-origin sheets throw; skip silently
                }
            }
        } catch (e) {
            // Stylesheets not accessible
        }

        // 3. Inline styles on html/body
        for (const el of [document.documentElement, document.body]) {
            if (el && el.style) {
                for (const prop of el.style) {
                    if (prop.startsWith('--') && !vars[prop]) {
                        vars[prop] = el.style.getPropertyValue(prop).trim();
                    }
                }
            }
        }

        return vars;
    }
    """

    try:
        raw = page.evaluate(script)
        if isinstance(raw, dict):
            result = raw
    except Exception as e:
        print(f"Warning: could not extract variables: {e}", file=sys.stderr)

    return result


def categorize_variables(raw: dict[str, str]) -> dict[str, dict[str, str]]:
    """Group variables by category."""
    categories: dict[str, dict[str, str]] = {
        "background": {},
        "foreground": {},
        "border": {},
        "button": {},
        "shadow": {},
        "accent": {},
        "icon": {},
        "semantic": {},
        "other": {},
    }

    for name, value in raw.items():
        cat = categorize_var(name)
        categories[cat][name] = value

    return categories


def build_pattern(url: str) -> str:
    """Build a fnmatch pattern from a URL."""
    from urllib.parse import urlparse

    parsed = urlparse(url)
    hostname = parsed.hostname or ""
    scheme = parsed.scheme or "https"

    if hostname.startswith("www."):
        hostname = hostname[4:]

    return f"{scheme}://{hostname}/*"


def analyze_site(url: str) -> dict[str, Any]:
    """Launch browser, analyze page, return structured analysis."""
    result: dict[str, Any] = {
        "url": url,
        "match_pattern": build_pattern(url),
        "total_variables": 0,
        "categories": {},
        "raw": {},
        "error": None,
    }

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context()
        page = context.new_page()

        try:
            page.goto(url, wait_until="networkidle", timeout=30000)
        except Exception as e:
            result["error"] = f"Failed to load page: {e}"
            browser.close()
            return result

        raw = extract_variables(page)
        result["raw"] = raw
        result["total_variables"] = len(raw)
        result["categories"] = categorize_variables(raw)

        browser.close()

    return result


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Analyze CSS custom properties on a website for Material theming."
    )
    parser.add_argument("url", help="URL of the page to analyze")
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=None,
        help="Output file path (default: stdout)",
    )
    parser.add_argument(
        "--pretty",
        action="store_true",
        default=True,
        help="Pretty-print JSON output (default: True)",
    )
    args = parser.parse_args()

    analysis = analyze_site(args.url)

    indent = 2 if args.pretty else None
    text = json.dumps(analysis, indent=indent, sort_keys=False)

    if args.output:
        args.output.write_text(text, encoding="utf-8")
        print(
            f"Wrote {analysis['total_variables']} variables to {args.output}",
            file=sys.stderr,
        )
    else:
        print(text)


if __name__ == "__main__":
    main()
