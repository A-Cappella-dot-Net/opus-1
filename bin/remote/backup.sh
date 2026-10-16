#!/bin/bash
# Usage: backup.sh <dir>
# Removes <dir>.bak (if any), renames <dir> to <dir>.bak (if it exists)
# and recreates <dir> empty, ready to receive the new files.
set -e
dir="${1%/}"
[ -n "$dir" ] || { echo "usage: backup.sh <dir>" >&2; exit 1; }
rm -rf "$dir.bak"
if [ -d "$dir" ]; then
  mv "$dir" "$dir.bak"
fi
mkdir -p "$dir"
