#!/bin/bash
# Usage: finish.sh <dir>
# Post-copy touches: normalize permissions, strip Windows line endings from
# scripts and make them executable.
set -e
dir="${1%/}"
[ -d "$dir" ] || { echo "finish.sh: $dir not found" >&2; exit 1; }
chmod 755 "$dir"
find "$dir" -type f -name '*.sh' -exec sed -i 's/\r$//' {} +
find "$dir" -type f -name '*.sh' -exec chmod +x {} +
