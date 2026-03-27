#!/bin/sh
# ============================================================
#  entrypoint.sh — JTrack JDash Container Startup Script
#  Waits for PostgreSQL, runs migrations, starts Gunicorn
# ============================================================

set -e

echo "🔍 Checking database connection..."

# Wait until PostgreSQL is ready
until nc -z "$DB_HOST" "$DB_PORT"; do
  echo "⏳ PostgreSQL at $DB_HOST:$DB_PORT is not ready — waiting..."
  sleep 2
done

echo "✅ PostgreSQL is ready!"

echo "📦 Running database migrations..."
python manage.py migrate --noinput

echo "📁 Collecting static files..."
python manage.py collectstatic --noinput --clear

echo "🚀 Starting Gunicorn server..."
exec gunicorn jdash.wsgi:application \
    --bind 0.0.0.0:"$PORT" \
    --workers 3 \
    --timeout 120 \
    --log-level info \
    --access-logfile - \
    --error-logfile -
