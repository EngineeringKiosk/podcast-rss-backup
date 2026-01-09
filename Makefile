.DEFAULT_GOAL := help

.PHONY: help
help: ## Outputs the help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: init
init: ## Check pre-requisites (curl, python3)
	@command -v curl >/dev/null 2>&1 || { echo "Error: curl is not installed"; exit 1; }
	@command -v python3 >/dev/null 2>&1 || { echo "Error: python3 is not installed"; exit 1; }
	@echo "All pre-requisites satisfied."

.PHONY: init-ruff
init-ruff: ## Check if ruff is installed
	@command -v ruff >/dev/null 2>&1 || { echo "Error: ruff is not installed. Install with: pip install ruff"; exit 1; }

.PHONY: format
format: init-ruff ## Format Python scripts with ruff
	ruff format scripts/

.PHONY: rss-backup
rss-backup: init ## Backup the RSS feed
	./scripts/backup-rss.sh https://engineeringkiosk.dev/podcast/rss
