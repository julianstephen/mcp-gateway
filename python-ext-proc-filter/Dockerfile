# Super simple Dockerfile
FROM python:3.12-slim
#FROM envoy-extproc-sdk-python:latest

COPY --from=docker.io/astral/uv:latest /uv /uvx /bin/

# Set working directory
WORKDIR /app

# Copy Python dependencies and source
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY src/ ./

RUN cd apex && uv pip install -r pyproject.toml --system
RUN cd apex && uv pip install . --system

# Expose the gRPC port
EXPOSE 50052

# Run the server
CMD ["python", "server.py"]
