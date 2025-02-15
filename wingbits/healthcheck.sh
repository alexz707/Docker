#!/bin/sh

# Check if the wingbits process is running
if ! pgrep wingbits > /dev/null; then
    echo "Error: wingbits process not running"
    exit 1
fi

# Check if GeoSigner is ready (unless disabled via env variable)
if [ -z "$DISABLE_GEOSIGNER_CHECK" ]; then
    if ! wingbits geosigner info | grep -q "GeoSigner is ready to use"; then
        echo "Error: GeoSigner is not ready"
        exit 1
    fi
fi
# If both checks pass, return success
exit 0
