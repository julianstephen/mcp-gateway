# CI-specific targets for GitHub Actions

# CI setup - lighter weight than local-env-setup, assumes Kind is already created
.PHONY: ci-setup
ci-setup: kind ## Setup environment for CI (creates Kind cluster if needed)
	@echo "Setting up CI environment..."
	# Create Kind cluster if it doesn't exist
	@if ! $(KIND) get clusters | grep -q mcp-gateway; then \
		echo "Creating Kind cluster..."; \
		$(KIND) create cluster --name mcp-gateway --config config/kind/cluster.yaml; \
	else \
		echo "Kind cluster 'mcp-gateway' already exists"; \
	fi
	# Install Gateway API CRDs
	$(KUBECTL) apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml
	$(KUBECTL) wait --for condition=Established --timeout=60s crd/gateways.gateway.networking.k8s.io
	# Build and load image
	$(MAKE) docker-build
	docker tag mcp-gateway:local ghcr.io/kagenti/mcp-gateway:latest
	$(call load-image,ghcr.io/kagenti/mcp-gateway:latest)
	# Install CRDs and deploy
	$(MAKE) install-crd
	$(MAKE) deploy
	# Wait for deployments
	$(KUBECTL) wait --for=condition=available --timeout=180s deployment/mcp-controller -n mcp-system
	$(KUBECTL) wait --for=condition=available --timeout=180s deployment/mcp-broker-router -n mcp-system
	# Deploy test servers
	$(MAKE) deploy-test-servers
	# Wait for all test server deployments to be available
	$(KUBECTL) wait --for=condition=available --timeout=180s deployment/mcp-test-server1 -n mcp-test
	$(KUBECTL) wait --for=condition=available --timeout=180s deployment/mcp-test-server2 -n mcp-test
	$(KUBECTL) wait --for=condition=available --timeout=180s deployment/mcp-test-server3 -n mcp-test
	$(KUBECTL) wait --for=condition=available --timeout=180s deployment/mcp-api-key-server -n mcp-test
	$(KUBECTL) wait --for=condition=available --timeout=180s deployment/mcp-custom-path-server -n mcp-test
	$(KUBECTL) wait --for=condition=available --timeout=180s deployment/mcp-oidc-server -n mcp-test

# Collect debug info on failure
.PHONY: ci-debug-logs
ci-debug-logs: ## Collect logs for debugging CI failures
	@echo "=== Controller logs ==="
	-$(KUBECTL) logs -n mcp-system deployment/mcp-controller --tail=100
	@echo "=== Broker logs ==="
	-$(KUBECTL) logs -n mcp-system deployment/mcp-broker-router --tail=100
	@echo "=== Test server logs ==="
	-$(KUBECTL) logs -n mcp-test deployment/mcp-test-server1 --tail=50
	-$(KUBECTL) logs -n mcp-test deployment/mcp-test-server2 --tail=50
	-$(KUBECTL) logs -n mcp-test deployment/mcp-test-server3 --tail=50
	@echo "=== MCPServers ==="
	-$(KUBECTL) get mcpservers -A
	@echo "=== HTTPRoutes ==="
	-$(KUBECTL) get httproutes -A
	@echo "=== ConfigMap ==="
	-$(KUBECTL) get configmap -n mcp-system mcp-gateway-config -o yaml
	@echo "=== Pods ==="
	-$(KUBECTL) get pods -A
