#!/bin/bash
set -e

echo "🔄 Hole aktuellen Code von GitHub..."
git pull origin main

echo "📦 Aktualisiere Container (pull + restart)..."
docker compose pull
docker compose up -d

echo "✅ Alle Dienste wurden aktualisiert und neu gestartet."
