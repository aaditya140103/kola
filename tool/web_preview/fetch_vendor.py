#!/usr/bin/env python3
"""Fetch third-party front-end assets for the Kola web preview harness.

Downloads pinned assets from the npm registry (reachable in restricted
networks where CDN hosts are blocked) and unpacks only the files the
harness needs into site/vendor/.

Dev-only tool for tool/web_preview; not part of the Kola product.
"""

from __future__ import annotations

import io
import json
import shutil
import tarfile
import urllib.request
from pathlib import Path

SITE = Path(__file__).resolve().parent / "site"
VENDOR = SITE / "vendor"

# package -> {version, files: [(tarball member, destination)]}
ASSETS = {
    "pdfjs-dist": {
        "version": "4.10.38",
        "files": [
            ("build/pdf.min.mjs", "pdfjs/pdf.min.mjs"),
            ("build/pdf.worker.min.mjs", "pdfjs/pdf.worker.min.mjs"),
        ],
    },
    "material-icons": {
        "version": "1.13.12",
        "files": [
            ("iconfont/material-icons-round.woff2", "material-icons-round.woff2"),
        ],
    },
    "@fontsource/roboto": {
        "version": "5.1.0",
        "files": [
            ("files/roboto-latin-400-normal.woff2", "roboto-400.woff2"),
            ("files/roboto-latin-500-normal.woff2", "roboto-500.woff2"),
            ("files/roboto-latin-700-normal.woff2", "roboto-700.woff2"),
        ],
    },
}


def fetch(url: str) -> bytes:
    with urllib.request.urlopen(url, timeout=60) as response:
        return response.read()


def main() -> None:
    VENDOR.mkdir(parents=True, exist_ok=True)
    for name, spec in ASSETS.items():
        scope = name.startswith("@")
        package = name.split("/")[-1] if scope else name
        tarball = f"{package}-{spec['version']}.tgz"
        url = f"https://registry.npmjs.org/{name}/-/{tarball}"
        print(f"Fetching {url}")
        data = fetch(url)
        with tarfile.open(fileobj=io.BytesIO(data), mode="r:gz") as archive:
            root = archive.getnames()[0].split("/")[0]
            for member, destination in spec["files"]:
                source = f"{root}/{member}"
                extracted = archive.extractfile(source)
                if extracted is None:
                    raise SystemExit(f"Missing member {source} in {name}")
                out_path = VENDOR / destination
                out_path.parent.mkdir(parents=True, exist_ok=True)
                out_path.write_bytes(extracted.read())
                print(f"  -> {out_path.relative_to(SITE)}")
    # Keep a marker of what was fetched, for freshness checks.
    (VENDOR / "vendor.json").write_text(
        json.dumps(
            {name: spec["version"] for name, spec in ASSETS.items()}, indent=2
        )
        + "\n"
    )
    print("Vendor assets ready.")


if __name__ == "__main__":
    main()
