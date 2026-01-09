.DEFAULT_GOAL := help

.PHONY: help
help: ## Outputs the help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: rss-backup
rss-backup: ## Backup the RSS feed
	mkdir -p rss_feed_backup
	curl https://engineeringkiosk.dev/podcast/rss -L > ./rss_feed_backup/$$(date +%Y-%m-%d).xml
