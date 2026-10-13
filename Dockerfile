# Use official lightweight Python image
FROM python:3.11-slim

# Prevent Python from writing pyc files and buffering stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1
ENV PORT=8080

WORKDIR /app

# Install system dependencies required by Python packages and OpenCV
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        gcc \
        libpq-dev \
        libxcb1 \
        libglib2.0-0 \
        libgl1 \
        libxext6 \
        libsm6 \
        libxrender1 \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip and packaging tools
RUN pip install --upgrade pip setuptools wheel

# Copy the project into the container
COPY . /app

# Install Python dependencies
RUN if [ -f requirements.txt ]; then \
        pip install -r requirements.txt; \
    elif [ -f pyproject.toml ]; then \
        pip install .; \
    else \
        echo "No requirements.txt or pyproject.toml found — skipping dependency install"; \
    fi

# Verify OpenCV can be imported during image build
RUN python -c "import cv2; print('OpenCV version:', cv2.__version__)"

# Create a non-root user for running the app
RUN useradd --create-home appuser \
    && chown -R appuser:appuser /app

USER appuser

# Cloud Run listens on port 8080
EXPOSE 8080

# Start the grading application
CMD ["python", "grade.py"]
