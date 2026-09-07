projectname?=go-template

PKG := github.com/nerdneilsfield/go-template
GOFILES := cmd internal pkg main.go

default: help

.PHONY: help
help: ## list makefile targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: build
build: ## build golang binary
	CGO_ENABLED=0 go build -ldflags "-X main.version=$(shell git describe --abbrev=0 --tags)" -o $(projectname)

.PHONY: install
install: ## install golang binary
	go install -ldflags "-X main.version=$(shell git describe --abbrev=0 --tags)"

.PHONY: run
run: ## run the app
	go run -ldflags "-X main.version=$(shell git describe --abbrev=0 --tags)" main.go

.PHONY: bootstrap
bootstrap: ## install build deps
	go generate -tags tools tools/tools.go

PHONY: test
test: clean ## display test coverage
	CGO_ENABLED=0 go test --cover -parallel=1 -v -coverprofile=coverage.out ./...
	go tool cover -func=coverage.out | sort -rnk3

PHONY: clean
clean: ## clean up environment
	@rm -rf coverage.out dist/ $(projectname)

PHONY: cover
cover: ## display test coverage
	CGO_ENABLED=0 go test -v -race $(shell go list ./... | grep -v /vendor/) -v -coverprofile=coverage.out
	go tool cover -func=coverage.out

PHONY: fmt
fmt: ## format go files
	gofumpt -l -w $(GOFILES)
	gofmt -w $(GOFILES)

PHONY: fmt-check
fmt-check: ## check go formatting
	@test -z "$$(gofumpt -l $(GOFILES))" || { echo "gofumpt: files need formatting"; exit 1; }
	@test -z "$$(gofmt -l $(GOFILES))" || { echo "gofmt: files need formatting"; exit 1; }

PHONY: vet
vet: ## run go vet
	go vet ./...

.PHONY: lint
lint: ## lint go files
	golangci-lint run -c .golangci.yml

.PHONY: check
check: fmt-check lint vet test release-check ## run all checks (fmt, lint, vet, test, release config)

.PHONY: release-check
release-check: ## validate goreleaser config
	goreleaser check

.PHONY: release-test
release-test: ## test release
	goreleaser release --snapshot --clean

# .PHONY: pre-commit
# pre-commit:	## run pre-commit hooks
# 	pre-commit run --all-files
