# E2E test targets

GINKGO = $(shell pwd)/bin/ginkgo
GINKGO_VERSION = v2.22.0

.PHONY: ginkgo
ginkgo: ## Download ginkgo locally if necessary
	@test -f $(GINKGO) || GOBIN=$(shell pwd)/bin go install github.com/onsi/ginkgo/v2/ginkgo@$(GINKGO_VERSION)

.PHONY: test-e2e-deps
test-e2e-deps: ginkgo ## Install e2e test dependencies
	go mod download

.PHONY: test-e2e-setup
test-e2e-setup: ## Setup cluster for e2e tests (if not already setup)
	@if ! kubectl get namespace mcp-system >/dev/null 2>&1; then \
		echo "Setting up cluster for e2e tests..."; \
		$(MAKE) tools; \
		$(MAKE) kind-create-cluster; \
		$(MAKE) build-and-load-image; \
		$(MAKE) gateway-api-install; \
		$(MAKE) istio-install; \
		$(MAKE) metallb-install; \
		$(MAKE) deploy-namespaces; \
		$(MAKE) deploy-gateway; \
		$(MAKE) deploy; \
		$(MAKE) deploy-test-servers; \
	else \
		echo "Cluster already setup, skipping..."; \
	fi

.PHONY: test-e2e-run
test-e2e-run: test-e2e-deps ## Run e2e tests (assumes cluster is ready)
	@echo "Running e2e tests..."
	$(GINKGO) -v --tags=e2e --timeout=5m ./tests/e2e

.PHONY: test-e2e
test-e2e: test-e2e-setup test-e2e-run ## Run full e2e test suite (setup + run)
	@echo "E2E tests completed"

.PHONY: test-e2e-local
test-e2e-local: test-e2e-deps ## Quick e2e test run for local development (no setup)
	@echo "Running e2e tests (local mode)..."
	$(GINKGO) -v --tags=e2e --timeout=2m --focus="Happy Path" ./tests/e2e

.PHONY: test-e2e-cleanup
test-e2e-cleanup: ## Clean up e2e test resources
	@echo "Cleaning up e2e test resources..."
	-kubectl delete mcpservers -n mcp-test --all
	-kubectl delete httproutes -n mcp-test -l test=e2e

.PHONY: test-e2e-watch
test-e2e-watch: test-e2e-deps ## Run e2e tests in watch mode for development
	$(GINKGO) watch -v --tags=e2e ./tests/e2e

# CI-specific target that assumes cluster exists
.PHONY: test-e2e-ci
test-e2e-ci: test-e2e-deps ## Run e2e tests in CI (no setup, fail fast)
	$(GINKGO) -v --tags=e2e --timeout=3m --fail-fast ./tests/e2e
