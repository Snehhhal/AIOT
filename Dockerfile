# PoleGuard - Enterprise Production Container for AI/IoT Electrical Safety Platform
FROM python:3.12-slim

# Prevent Python from buffering stdout/stderr and writing .pyc files
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

WORKDIR /app

# Install system utilities for health checks and binary wheels
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install python dependencies
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r /app/requirements.txt

# Copy application source code and models
COPY backend /app/backend
COPY ai /app/ai
COPY rag /app/rag
COPY docs /app/docs

# Create directory for uploads and local sqlite db
RUN mkdir -p /app/uploads /app/data

# Expose FastAPI REST and WebSocket port
EXPOSE 8000

# Container healthcheck
HEALTHCHECK --interval=20s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Default runtime command
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]
