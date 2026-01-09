# Podcast RSS Backup

A regular backup of the RSS feed from the [Engineering Kiosk Podcast](https://engineeringkiosk.dev/).

## Overview

This repository automatically backs up the RSS feed from Engineering Kiosk Podcast on a monthly basis. Each backup includes:

- The RSS feed content (XML format)
- Request and response headers (JSON format)

## Usage

### Manual Backup

Run the backup manually using Make:

```bash
make rss-backup
```

Or run the script directly:

```bash
./scripts/backup-rss.sh https://engineeringkiosk.dev/podcast/rss
```

### Script Options

The backup script accepts the RSS feed URL as a command-line argument:

```bash
./scripts/backup-rss.sh <RSS_FEED_URL>
```

Features:
- Follows HTTP redirects
- Stores RSS content with date-based naming (`YYYY-MM-DD.xml`)
- Captures request and response headers in JSON format (`YYYY-MM-DD_headers.json`)
- Validates downloaded content is valid XML/RSS
- Proper exit codes for error handling

## Automated Backups

The repository uses GitHub Actions to automatically backup the RSS feed:

- **Schedule**: Monthly on the 1st day of each month at 00:00 UTC
- **Manual trigger**: Can be triggered manually via workflow_dispatch

Backups are automatically committed to the repository.

## Make Commands

| Command | Description |
|---------|-------------|
| `make help` | Show available commands |
| `make init` | Check pre-requisites (curl, python3) |
| `make init-ruff` | Check if ruff is installed |
| `make format` | Format Python scripts with ruff |
| `make rss-backup` | Backup the RSS feed |
