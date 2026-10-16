# Use official lightweight Python image for CLI tool
FROM python:3.11-slim

# Prevent Python from writing pyc files and buffering stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

WORKDIR /app

# Install system dependencies required by Python packages and OpenCV
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        gcc \
        libpq-dev \
        libglib2.0-0 \
        libgl1 \
        libxext6 \
        libsm6 \
        libxrender1 \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip and packaging tools
RUN pip install --upgrade pip setuptools wheel

# Copy only requirements first to leverage Docker layer caching
COPY requirements.txt /app/

# Install Python dependencies (if requirements.txt exists)
RUN if [ -f requirements.txt ]; then \
        pip install -r requirements.txt; \
    else \
        echo "No requirements.txt found — skipping dependency install"; \
    fi

# Copy the rest of the project into the container
COPY . /app

# Create a models directory (weights are not tracked by git; mount or copy them at runtime)
RUN mkdir -p /app/models

# Verify OpenCV can be imported at build time (fail early if system deps missing)
RUN python -c "import cv2; print('OpenCV version:', cv2.__version__)"

# Create a non-root user for running the app
RUN useradd --create-home appuser \
    && chown -R appuser:appuser /app

USER appuser

# This project is a CLI tool (grade.py). Use the container like:
#   docker run --rm -v $(pwd)/models:/app/models image_name tray_photo.jpg
# Default entrypoint runs the CLI. Provide the image or folder path as arguments.
ENTRYPOINT ["python", "grade.py"]
CMD ["--help"]
