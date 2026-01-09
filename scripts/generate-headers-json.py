#!/usr/bin/env python3
"""
Generate a JSON file containing HTTP request and response headers.

Usage: generate-headers-json.py <response_headers_file> <rss_url> <http_code> <output_file>
"""

import json
import sys
from datetime import datetime, timezone


def parse_response_headers(headers_file: str) -> dict:
    """Parse response headers from a file into a dictionary."""
    headers = {}
    with open(headers_file, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            if line.startswith("HTTP/"):
                headers["status_line"] = line
            elif ":" in line:
                key, value = line.split(":", 1)
                headers[key.strip()] = value.strip()
    return headers


def generate_headers_json(
    response_headers_file: str, rss_url: str, http_code: int
) -> dict:
    """Generate the complete headers JSON structure."""
    response_headers = parse_response_headers(response_headers_file)

    request_headers = {
        "User-Agent": "curl/RSS-Backup-Script",
        "Accept": "application/rss+xml, application/xml, text/xml, */*",
        "Accept-Encoding": "gzip, deflate",
    }

    return {
        "backup_timestamp": datetime.now(timezone.utc)
        .isoformat()
        .replace("+00:00", "Z"),
        "url": rss_url,
        "request": {"method": "GET", "headers": request_headers},
        "response": {"http_code": http_code, "headers": response_headers},
    }


def main():
    if len(sys.argv) != 5:
        print(
            f"Usage: {sys.argv[0]} <response_headers_file> <rss_url> <http_code> <output_file>",
            file=sys.stderr,
        )
        sys.exit(1)

    response_headers_file = sys.argv[1]
    rss_url = sys.argv[2]
    http_code = int(sys.argv[3])
    output_file = sys.argv[4]

    output = generate_headers_json(response_headers_file, rss_url, http_code)

    with open(output_file, "w") as f:
        json.dump(output, f, indent=2)
        f.write("\n")


if __name__ == "__main__":
    main()
