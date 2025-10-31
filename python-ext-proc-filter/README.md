### Build proto

1. Install protoc. See instructions if [needed](https://betterproto.github.io/python-betterproto2/getting-started/)
- Install the proto compiler and tools: 
```
pip install grpcio-tools
pip install betterproto2_compiler
```
2. Build the python `envoy` protobufs
- Code to help pull and build the python code from proto files: https://github.com/cetanu/envoy\_data\_plane.git
- Run: python utils/download\_protobufs.py
NOTE: This will build the envoy proto in src/envoy\_data\_plane\_pb2. Copy the src/envoy\_data\_plane\_pb2/envoy to where you need it. 
3. Get the python xds protobufs:
```
git clone https://github.com/cncf/xds.git
```
NOTE: This repo contains the python code for `validate, xds, udpa`. Go to folder python. Copy the needed folders or run
setup.py to install.
4. In the end you need `envoy, validate, xds, udpa` python protobufs folders copied into `src` to run example server.py
5. Run `python server.py`

### Build docker image and add to cluster

From `python-ext-proc-filter` folder

```
docker build -t ej-extproc-server:latest .
kind load docker-image ej-extproc-server:latest --name mcp-gateway
kubectl apply -f ext-proc.yaml 
kubectl apply -f filter.yaml 
```

### Enable debug logs for mcp-gateway envoy routes if needed
* From mcp-gateway folder: 
`make debug-envoy-impl`


### Use with CF Plugin Manager
1. git clone https://github.ibm.com/security-foundation-models/apex.git into python-ext-proc-filter/src/
2. src/server.py is the grpc server and intergates CF Plugin Manager. It initializes the Plugin Manager using the
config.yaml in python-ext-proc-filter/src/apex/resouces/config/config.yaml.
3. Use Dockerfile to build and push ext\_proc into kind cluster. Use Makefile for some shortcuts.
