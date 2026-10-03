# Thin wrapper around scripts/*.R so `make build`, `make lint`, etc. work
# everywhere make does. The scripts remain the source of truth.

.PHONY: build lint style spellcheck coverage docs release-check

build:
	Rscript scripts/build-all.R

lint:
	Rscript scripts/lint-all.R

style:
	Rscript scripts/style-all.R

spellcheck:
	Rscript scripts/spellcheck-all.R

coverage:
	Rscript scripts/coverage.R

docs:
	Rscript scripts/build-all.R
	Rscript scripts/build-docs.R

## What CI runs before any merge:
release-check: lint build
