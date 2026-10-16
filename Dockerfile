FROM python:3.10-slim

# System libraries required for OpenCV and PyTorch/Ultralytics image handling
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy dependency definition and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code and pre-downloaded weights in models/
COPY . .

# Expose default Cloud Run port
EXPOSE 8080

# Cloud Run injects the PORT environment variable; launch uvicorn bound to 0.0.0.0
CMD exec uvicorn main:app --host 0.0.0.0 --port ${PORT:-8080}
