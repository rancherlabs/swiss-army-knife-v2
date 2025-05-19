# Get git commit hash
GIT_COMMIT := $(shell git rev-parse --short HEAD)

# Try to get the tag, if it exists
GIT_TAG := $(shell git describe --tags --exact-match HEAD 2>/dev/null)

# Set TAG based on whether a git tag exists
ifdef GIT_TAG
    # We're on a tagged commit, use the tag
    TAG := $(GIT_TAG)
else
    # Not on a tag, use build-{commit} format
    TAG := build-$(GIT_COMMIT)
endif

# Default target
.PHONY: all
all: build

# Build target
.PHONY: build
build:
	go build -o echo-server main.go

# Log target - outputs variables for CI/CD
.PHONY: log
log:
	@echo "TAG=$(TAG)"
	@echo "BUILD_DATE=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")"
	@echo "GIT_COMMIT=$(GIT_COMMIT)"
