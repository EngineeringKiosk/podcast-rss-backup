#!/bin/bash
#
# RSS Feed Backup Script
#
# Downloads an RSS feed and stores it with date-based naming.
# Also captures request and response headers in JSON format.
#
# Usage: ./backup-rss.sh <RSS_FEED_URL>
#

set -euo pipefail

# Configuration
BACKUP_DIR="rss_feed_backup"
DATE=$(date +%Y-%m-%d)
BACKUP_FILE="${BACKUP_DIR}/${DATE}.xml"
HEADERS_FILE="${BACKUP_DIR}/${DATE}_headers.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to print error messages
error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

# Function to print success messages
success() {
    echo -e "${GREEN}$1${NC}"
}

# Function to show usage
usage() {
    echo "Usage: $0 <RSS_FEED_URL>"
    echo ""
    echo "Downloads an RSS feed and stores it as a backup."
    echo "Also captures request and response headers in JSON format."
    echo ""
    echo "Arguments:"
    echo "  RSS_FEED_URL    The URL of the RSS feed to backup"
    echo ""
    echo "Example:"
    echo "  $0 https://engineeringkiosk.dev/podcast/rss"
}

# Check if URL argument is provided
if [[ $# -lt 1 ]]; then
    error "No RSS feed URL provided"
    usage
    exit 1
fi

RSS_URL="$1"

# Validate URL format (basic check)
if [[ ! "$RSS_URL" =~ ^https?:// ]]; then
    error "Invalid URL format. URL must start with http:// or https://"
    exit 1
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Create temporary file for response headers
RESPONSE_HEADERS_TMP=$(mktemp)

# Cleanup function (invoked via trap)
# shellcheck disable=SC2317,SC2329
cleanup() {
    rm -f "$RESPONSE_HEADERS_TMP"
}
trap cleanup EXIT

echo "Starting RSS feed backup..."
echo "URL: $RSS_URL"
echo "Date: $DATE"

# Download the RSS feed with headers
# -L: Follow redirects
# -D: Dump response headers to file
# -s: Silent mode
# -S: Show errors
# -f: Fail on HTTP errors
# --compressed: Request compressed response and decompress
echo "Downloading RSS feed..."

HTTP_CODE=$(curl \
    -L \
    -D "$RESPONSE_HEADERS_TMP" \
    -s \
    -S \
    -w "%{http_code}" \
    -H "User-Agent: curl/RSS-Backup-Script" \
    -H "Accept: application/rss+xml, application/xml, text/xml, */*" \
    --compressed \
    -o "$BACKUP_FILE" \
    "$RSS_URL" 2>&1) || {
    error "Failed to download RSS feed"
    exit 1
}

# Check HTTP response code
if [[ "$HTTP_CODE" -lt 200 || "$HTTP_CODE" -ge 300 ]]; then
    error "HTTP request failed with status code: $HTTP_CODE"
    rm -f "$BACKUP_FILE"
    exit 1
fi

# Verify the downloaded file is not empty
if [[ ! -s "$BACKUP_FILE" ]]; then
    error "Downloaded file is empty"
    rm -f "$BACKUP_FILE"
    exit 1
fi

# Verify the file looks like XML (basic check)
if ! head -c 100 "$BACKUP_FILE" | grep -q "<?xml\|<rss\|<feed"; then
    error "Downloaded content does not appear to be valid XML/RSS"
    rm -f "$BACKUP_FILE"
    exit 1
fi

echo "Creating headers JSON file..."

# Convert headers to JSON and save
python3 << EOF > "$HEADERS_FILE"
import json
from datetime import datetime, timezone

# Parse response headers
response_headers = {}
with open('$RESPONSE_HEADERS_TMP', 'r') as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        if line.startswith('HTTP/'):
            response_headers['status_line'] = line
        elif ':' in line:
            key, value = line.split(':', 1)
            response_headers[key.strip()] = value.strip()

# Request headers (as configured in curl)
request_headers = {
    "User-Agent": "curl/RSS-Backup-Script",
    "Accept": "application/rss+xml, application/xml, text/xml, */*",
    "Accept-Encoding": "gzip, deflate"
}

# Create the final JSON structure
output = {
    "backup_timestamp": datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z'),
    "url": "$RSS_URL",
    "request": {
        "method": "GET",
        "headers": request_headers
    },
    "response": {
        "http_code": $HTTP_CODE,
        "headers": response_headers
    }
}

print(json.dumps(output, indent=2))
EOF

# Output summary
FILESIZE=$(wc -c < "$BACKUP_FILE" | tr -d ' ')
success "Backup completed successfully!"
echo "  RSS backup:     $BACKUP_FILE ($FILESIZE bytes)"
echo "  Headers backup: $HEADERS_FILE"

exit 0
