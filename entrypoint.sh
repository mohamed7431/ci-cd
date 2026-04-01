#!/bin/sh
# ============================================================
#  entrypoint.sh — JTrack JDash Container Startup Script
#  Waits for DB, runs migrations if app code exists, starts Gunicorn
# ============================================================

set -e

echo "Checking database connection..."

# Wait until the database is ready
until nc -z "$DB_HOST" "$DB_PORT"; do
    echo "Database at $DB_HOST:$DB_PORT is not ready - waiting..."
    sleep 2
done

echo "Database is ready!"

# Only run Django commands if manage.py exists
if [ -f /app/manage.py ]; then
    echo "Running database migrations..."
    python manage.py migrate --noinput

    echo "Collecting static files..."
    python manage.py collectstatic --noinput --clear
else
    echo "WARNING: manage.py not found - skipping migrations and collectstatic."
    echo "         Add the JTrack app code to the repo to enable this step."
fi

echo "Starting Gunicorn server..."
exec gunicorn jdash.wsgi:application \
    --bind 0.0.0.0:"$PORT" \
    --workers 3 \
    --timeout 120 \
    --log-level info \
    --access-logfile - \
    --error-logfile -
