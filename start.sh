#!/bin/sh
set -e

echo "Starting app..."
/app/bin/ingest_umbrella eval "Ingest.Release.migrate";
/app/bin/ingest_umbrella start;