# Include logic that can be reused across projects.
include hack/make/build.mk

# Define target platforms, image builder and the fully qualified image name.
TARGET_PLATFORMS ?= linux/amd64,linux/arm64

REPO ?= rancherlabs
IMAGE ?= swiss-army-knife
IMAGE_NAME = $(REPO)/$(IMAGE)
FULL_IMAGE_TAG = $(IMAGE_NAME):$(TAG)
BUILD_ACTION = --load

# Default target
.PHONY: all
all: build

# Build target (for local Go binary)
.PHONY: build
build:
	go build -o echo-server main.go

build-image: buildx-machine ## build (and load) the container image targeting the current platform.
	$(IMAGE_BUILDER) build -f Dockerfile \
		--builder $(MACHINE) $(IMAGE_ARGS) \
		--build-arg VERSION=$(VERSION) --platform=$(TARGET_PLATFORMS) -t "$(FULL_IMAGE_TAG)" $(BUILD_ACTION) .
	@echo "Built $(FULL_IMAGE_TAG)"

build-validate: buildx-machine ## build (and load) the container image targeting the current platform.
	mkdir -p ci
	$(IMAGE_BUILDER) build -f Dockerfile \
		--builder $(MACHINE) $(IMAGE_ARGS) \
		--build-arg VERSION=$(VERSION) \
		--platform=$(TARGET_PLATFORMS) \
		--output type=oci,dest=ci/multiarch-image.oci \
		-t "$(FULL_IMAGE_TAG)" .
	@echo "Built $(FULL_IMAGE_TAG) multi-arch image saved to ci/multiarch-image.oci"

push-image: validate buildx-machine ## build the container image targeting all platforms defined by TARGET_PLATFORMS and push to a registry.
	$(IMAGE_BUILDER) build -f Dockerfile \
		--builder $(MACHINE) $(IMAGE_ARGS) $(IID_FILE_FLAG) $(BUILDX_ARGS) \
		--build-arg VERSION=$(VERSION) --platform=$(TARGET_PLATFORMS) -t "$(FULL_IMAGE_TAG)" --push .
	@echo "Pushed $(FULL_IMAGE_TAG)"

validate: validate-dirty ## Run validation checks.

validate-dirty:
ifdef DIRTY
	@echo Git is dirty
	@git --no-pager status
	@git --no-pager diff
	@exit 1
endif

# Log target - outputs variables for CI/CD
.PHONY: log
log:
	@echo "TAG=$(TAG)"
	@echo "VERSION=$(VERSION)"
	@echo "BUILD_DATE=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")"
	@echo "GIT_COMMIT=$(shell git rev-parse --short HEAD)"

clean: ## clean up project.
	rm -rf build
	rm -rf ci
	rm -f echo-server
