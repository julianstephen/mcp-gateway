# Super simple Dockerfile
FROM python:3.12-slim
#FROM envoy-extproc-sdk-python:latest

# Set working directory
WORKDIR /app

# Copy Python dependencies and source
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY src/ ./

# Expose the gRPC port
EXPOSE 50052

# Run the server
CMD ["python", "server.py"]
# CMD ["tail", "-f", "/dev/null"]
