.PHONY: build load all deploy exec log

# Build the combined broker and router 
build:
	docker build -t localhost/my-ext-proc:0.1.0 .


load:
	kind load docker-image localhost/my-ext-proc:0.1.0 --name mcp-gateway

podname := $(shell kubectl get pods -A |grep my-extproc | grep -v Terminating | awk '{print $$2}')
log:
	kubectl logs ${podname} -n istio-system -f

exec:
	kubectl exec -ti ${podname} -n istio-system -- bash

deploy:
	kubectl delete -f ext-proc.yaml
	kubectl apply -f ext-proc.yaml
	kubectl apply -f filter.yaml

all: build load deploy
	@echo "All done!"