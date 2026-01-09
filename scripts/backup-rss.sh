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

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
BACKUP_DIR="rss_feed_backup"
DATE=$(date +%Y-%m-%d)
BACKUP_FILE="${BACKUP_DIR}/${DATE}.xml"
HEADERS_FILE="${BACKUP_DIR}/${DATE}_headers.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to get current timestamp in European format
timestamp() {
    date +"%d.%m.%Y %H:%M:%S"
}

# Function to print log messages with timestamp
log() {
    echo -e "[$(timestamp)] $1"
}

# Function to print error messages with timestamp
error() {
    echo -e "[$(timestamp)] ${RED}ERROR: $1${NC}" >&2
}

# Function to print success messages with timestamp
success() {
    echo -e "[$(timestamp)] ${GREEN}$1${NC}"
}

# Function to show usage
usage() {
    log "Usage: $0 <RSS_FEED_URL>"
    log ""
    log "Downloads an RSS feed and stores it as a backup."
    log "Also captures request and response headers in JSON format."
    log ""
    log "Arguments:"
    log "  RSS_FEED_URL    The URL of the RSS feed to backup"
    log ""
    log "Example:"
    log "  $0 https://engineeringkiosk.dev/podcast/rss"
}

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        error "Required command '$1' is not installed. Please install it and try again."
        exit 1
    fi
}

# Pre-requisite checks
log "Checking pre-requisites..."
check_command "curl"
check_command "python3"
log "All pre-requisites satisfied."

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

log "Starting RSS feed backup..."
log "URL: $RSS_URL"
log "Date: $DATE"

# Download the RSS feed with headers
# -L: Follow redirects
# -D: Dump response headers to file
# -s: Silent mode
# -S: Show errors
# -f: Fail on HTTP errors
# --compressed: Request compressed response and decompress
log "Downloading RSS feed..."

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

log "Creating headers JSON file..."

# Generate headers JSON using external Python script
python3 "${SCRIPT_DIR}/generate-headers-json.py" \
    "$RESPONSE_HEADERS_TMP" \
    "$RSS_URL" \
    "$HTTP_CODE" \
    "$HEADERS_FILE"

# Output summary
FILESIZE=$(wc -c < "$BACKUP_FILE" | tr -d ' ')
success "Backup completed successfully!"
log "  RSS backup:     $BACKUP_FILE ($FILESIZE bytes)"
log "  Headers backup: $HEADERS_FILE"

exit 0
