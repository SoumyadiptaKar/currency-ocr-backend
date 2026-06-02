#!/usr/bin/env bash
set -euo pipefail

# Simple local runner for development
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

echo "Installing dependencies (skip if already installed)..."
python3 -m pip install -r requirements.txt

echo "Starting Flask app on ${PORT:-5000}..."
python3 backend.py
