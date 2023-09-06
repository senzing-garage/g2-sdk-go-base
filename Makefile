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
BUILD_VERSION := $(shell git describe --always --tags --abbrev=0 --dirty  | sed 's/v//')
BUILD_TAG := $(shell git describe --always --tags --abbrev=0  | sed 's/v//')
BUILD_ITERATION := $(shell git log $(BUILD_TAG)..HEAD --oneline | wc -l | sed 's/^ *//')
GIT_REMOTE_URL := $(shell git config --get remote.origin.url)
GO_PACKAGE_NAME := $(shell echo $(GIT_REMOTE_URL) | sed -e 's|^git@github.com:|github.com/|' -e 's|\.git$$||' -e 's|Senzing|senzing|')
PATH := $(MAKEFILE_DIRECTORY)/bin:$(PATH)

# Recursive assignment ('=')

# CC = gcc
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
# -----------------------------------------------------------------------------

PLATFORMS := darwin/amd64 linux/amd64 windows/amd64
$(PLATFORMS):
	@echo Building $(TARGET_DIRECTORY)/$(GO_OS)-$(GO_ARCH)/$(PROGRAM_NAME)
	@mkdir -p $(TARGET_DIRECTORY)/$(GO_OS)-$(GO_ARCH) || true
	echo GOOS=$(GO_OS) GOARCH=$(GO_ARCH) go build $(GO_BUILDMODE) -o $(TARGET_DIRECTORY)/$(GO_OS)-$(GO_ARCH)/$(PROGRAM_NAME)

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
clean: clean-platform
	@go clean -cache
	@go clean -testcache


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


.PHONY: update-pkg-cache
update-pkg-cache:
	@GOPROXY=https://proxy.golang.org GO111MODULE=on \
		go get $(GO_PACKAGE_NAME)@$(BUILD_TAG)
