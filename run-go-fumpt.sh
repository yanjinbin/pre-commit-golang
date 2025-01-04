#!/usr/bin/env bash
#
# Capture and print stdout, since gofumpt doesn't use proper exit codes
#
set -e -o pipefail

# Check if gofumpt is installed
if ! command -v gofumpt &> /dev/null ; then
    echo "gofumpt not installed or available in the PATH. Attempting to install..." >&2
    if ! go install mvdan.cc/gofumpt@latest; then
        echo "Failed to install gofumpt. Please ensure Go is installed and configured correctly." >&2
        exit 1
    fi
    echo "gofumpt installed successfully."
fi

# Run gofumpt and capture the output
output="$(gofumpt -l -w "$@")"
echo "$output"
[[ -z "$output" ]]
