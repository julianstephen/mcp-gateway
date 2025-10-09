.PHONY: build push deploy load

# Build the combined broker and router 
build:
	 docker build -t ej-extproc-server:latest .


load:
	kind load docker-image localhost/ej-extproc-server:latest --name mcp-gateway

all: build load
	kubectl delete -f ext-proc.yaml
	kubectl apply -f ext-proc.yaml
