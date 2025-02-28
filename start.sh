#!/bin/sh
set -e

echo "Starting app..."
/app/bin/ingest eval "Ingest.Release.migrate";
/app/bin/ingest start;