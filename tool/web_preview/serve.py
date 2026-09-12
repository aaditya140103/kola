#!/usr/bin/env python3
"""Static server for the Kola web preview harness.

Binds 0.0.0.0 so the preview is reachable through the sandbox proxy.
Includes a MIME override: Python's http.server does not know .mjs, and
browsers refuse module scripts served as text/plain.

Dev-only tool for tool/web_preview; not part of the Kola product.
"""

from __future__ import annotations

import http.server
import socketserver

HOST = "0.0.0.0"
PORT = 8080

MIME_OVERRIDES = {
    ".mjs": "text/javascript; charset=utf-8",
    ".js": "text/javascript; charset=utf-8",
    ".json": "application/json; charset=utf-8",
    ".woff2": "font/woff2",
    ".pdf": "application/pdf",
}


class PreviewHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def guess_type(self, path):
        for suffix, mime in MIME_OVERRIDES.items():
            if path.endswith(suffix):
                return mime
        return super().guess_type(path)


def main() -> None:
    socketserver.ThreadingTCPServer.allow_reuse_address = True
    with socketserver.ThreadingTCPServer((HOST, PORT), PreviewHandler) as httpd:
        print(f"Kola preview harness serving on http://{HOST}:{PORT}")
        httpd.serve_forever()


if __name__ == "__main__":
    main()
