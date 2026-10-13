# Use official lightweight Python image
FROM python:3.11-slim

# Prevent Python from writing pyc files and buffering stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

WORKDIR /app

# Install system deps commonly required to build Python packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential gcc libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip and tooling
RUN pip install --upgrade pip setuptools wheel

# Copy the project into the container
COPY . /app

# Install Python dependencies if a requirements file or pyproject exists
RUN if [ -f requirements.txt ]; then \
        pip install -r requirements.txt; \
    elif [ -f pyproject.toml ]; then \
        pip install .; \
    else \
        echo "No requirements.txt or pyproject.toml found — skipping dependency install"; \
    fi

# Create a non-root user for running the app
RUN useradd --create-home appuser && chown -R appuser /app
USER appuser

# Expose a default port (change if your app uses a different port)
EXPOSE 8080

# Default command — change to your project's entrypoint
CMD ["python", "grade.py"]
