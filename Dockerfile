# ============================================================
#  JTrack JDash Dashboard — Dockerfile
#  Stack: Python 3.11 + Django + Gunicorn + MariaDB (PyMySQL)
#  Multi-stage build: builder -> production
# ============================================================

# ── Stage 1: Builder ─────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /usr/src/app

# Install system deps needed to compile packages
# default-libmysqlclient-dev is needed by some mysql-related packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    pkg-config \
    default-libmysqlclient-dev \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN pip install --upgrade pip

# Copy and wheel all dependencies
COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /usr/src/app/wheels \
    -r requirements.txt


# ── Stage 2: Production Image ────────────────────────────────
FROM python:3.11-slim

# Create non-root user for security
RUN groupadd -r jtrack && useradd -r -g jtrack jtrack

# Runtime system dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    default-libmysqlclient-dev \
    netcat-traditional \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy compiled wheels from builder and install
COPY --from=builder /usr/src/app/wheels /wheels
RUN pip install --no-cache /wheels/*

# Copy JTrack dashboard source code
COPY . /app/

# Copy entrypoint script and make it executable
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Create directories for static and media files
RUN mkdir -p /app/staticfiles /app/mediafiles \
    && chown -R jtrack:jtrack /app

# Django environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DJANGO_SETTINGS_MODULE=jdash.settings.production \
    PORT=8000

# Switch to non-root user
USER jtrack

# Expose Gunicorn port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8000/health/ || exit 1

# Start the app
ENTRYPOINT ["/app/entrypoint.sh"]
