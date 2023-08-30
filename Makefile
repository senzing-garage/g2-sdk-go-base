# Makefile for g2-sdk-go-base.

# Detect the operating system and architecture.

include Makefile.osdetect

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

# "Simple expanded" variables (':=')

# PROGRAM_NAME is the name of the GIT repository.
PROGRAM_NAME := $(notdir $(shell git rev-parse --show-toplevel))
MAKEFILE_PATH := $(subst /,$(PATH_SEPARATOR),$(abspath $(filter makefile Makefile,$(MAKEFILE_LIST))))
MAKEFILE_DIRECTORY := $(dir $(MAKEFILE_PATH))
TARGET_DIRECTORY := $(MAKEFILE_DIRECTORY)target
DOCKER_CONTAINER_NAME := $(PROGRAM_NAME)
DOCKER_IMAGE_NAME := senzing/$(PROGRAM_NAME)
DOCKER_BUILD_IMAGE_NAME := $(DOCKER_IMAGE_NAME)-build
BUILD_VERSION := $(subst v,,$(shell git describe --always --tags --abbrev=0 --dirty))
BUILD_TAG := $(subst v,,$(shell git describe --always --tags --abbrev=0))
BUILD_ITERATION := $(strip $(shell git log $(BUILD_TAG)..HEAD --oneline | $(LINE_COUNT)))
GIT_REMOTE_URL := $(shell git config --get remote.origin.url)
GO_PACKAGE_NAME := $(subst Senzing,senzing,$(subst .git,,$(subst git@github.com,github.com,$(GIT_REMOTE_URL))))
GO_OSARCH = $(subst /, ,$@)
GO_OS = $(word 1, $(GO_OSARCH))
GO_ARCH = $(word 2, $(GO_OSARCH))

# Conditional assignment. ('?=')
# Can be overridden with "export"
# Example: "export LD_LIBRARY_PATH=/path/to/my/senzing/g2/lib"

# Optionally override the database URL for running automated tests.  The 
# conditional assignment ('?=') can be overridden with with a shell environment
# variable.  If SENZING_TOOLS_DATABASE_URL is not set then a SQLite3 database
# in the ./target/test/{test-suite} directory is used for each test suite.

#SENZING_TOOLS_DATABASE_URL ?= postgresql://username:password@hostname:5432:database/?schema=schemaname

# Export environment variables.

.EXPORT_ALL_VARIABLES:

# -----------------------------------------------------------------------------
# The first "make" target runs as default.
# -----------------------------------------------------------------------------

.PHONY: default
default: help

# -----------------------------------------------------------------------------
# Operating System / Architecture targets
# -----------------------------------------------------------------------------

-include Makefile.$(OSTYPE)
-include Makefile.$(OSTYPE)_$(OSARCH)

# -----------------------------------------------------------------------------
# Dependency management
# -----------------------------------------------------------------------------

.PHONY: dependencies
dependencies:
	@go get -u ./...
	@go get -t -u ./...
	@go mod tidy

# -----------------------------------------------------------------------------
# Build
#  - The "build" target is implemented in Makefile.OS.ARCH files.
#  - docker-build: https://docs.docker.com/engine/reference/commandline/build/
# -----------------------------------------------------------------------------

PLATFORMS := darwin/amd64 linux/amd64 windows/amd64
$(PLATFORMS):
	@echo Building $(TARGET_DIRECTORY)/$(GO_OS)-$(GO_ARCH)/$(PROGRAM_NAME)
	@mkdir -p $(TARGET_DIRECTORY)/$(GO_OS)-$(GO_ARCH) || true
	@GOOS=$(GO_OS) GOARCH=$(GO_ARCH) go build -o $(TARGET_DIRECTORY)/$(GO_OS)-$(GO_ARCH)/$(PROGRAM_NAME)

# -----------------------------------------------------------------------------
# Test
#  - The "test" target is implemented in Makefile.OS.ARCH files.
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Run
#  - The "run" target is implemented in Makefile.OS.ARCH files.
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Package
#  - The "package" target is implemented in Makefile.OS.ARCH files.
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Utility targets
# -----------------------------------------------------------------------------

.PHONY: clean
clean:
	@go clean -cache
	@go clean -testcache
	@docker rm --force $(DOCKER_CONTAINER_NAME) 2> /dev/null || true
	@docker rmi --force $(DOCKER_IMAGE_NAME) $(DOCKER_BUILD_IMAGE_NAME) 2> /dev/null || true
	@rm -rf $(TARGET_DIRECTORY) || true
	@rm -f $(GOPATH)/bin/$(PROGRAM_NAME) || true
	@rm -rf /tmp/$(PROGRAM_NAME)


.PHONY: help
help:
	@echo "Build $(PROGRAM_NAME) version $(BUILD_VERSION)-$(BUILD_ITERATION)".
	@echo "Makefile targets:"
	@$(MAKE) -pRrq -f $(firstword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | xargs


.PHONY: print-make-variables
print-make-variables:
	@$(foreach V,$(sort $(.VARIABLES)), \
		$(if $(filter-out environment% default automatic, \
		$(origin $V)),$(warning $V=$($V) ($(value $V)))))


.PHONY: setup
setup:
	@echo "No setup required."


.PHONY: update-pkg-cache
update-pkg-cache:
	@GOPROXY=https://proxy.golang.org GO111MODULE=on \
		go get $(GO_PACKAGE_NAME)@$(BUILD_TAG)
