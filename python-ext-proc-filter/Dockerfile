# Super simple Dockerfile
#FROM python:3.12.12
#FROM envoy-extproc-sdk-python:latest
FROM public.ecr.aws/docker/library/python:3.12.12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && apt-get purge -y --auto-remove \
    && rm -rf /var/lib/apt/lists/*

COPY --from=docker.io/astral/uv:latest /uv /uvx /bin/

# Set working directory
WORKDIR /app

# Copy Python dependencies and source
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN mkdir resources
COPY src/ ./

COPY resources ./resources/
# RUN cd apex && uv pip install -r pyproject.toml --system
# RUN cd apex && uv pip install . --system

# Expose the gRPC port
EXPOSE 50052

# Run the server
CMD ["python", "server.py"]
