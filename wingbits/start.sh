#!/usr/bin/env bash

# Determine the architecture
GOOS="linux"
case "$(uname -m)" in
	x86_64)
		GOARCH="amd64"
		;;
	i386|i686)
		GOARCH="386"
		;;
	armv7l)
		GOARCH="arm"
		;;
	aarch64|arm64)
		GOARCH="arm64"
		;;
	*)
		echo "Unsupported architecture"
  		exit 1
		;;
esac

WINGBITS_PATH="/usr/local/bin"
WINGBITS_VERSION_PATH="/etc/wingbits"
local_version=$(cat $WINGBITS_VERSION_PATH/version)
local_json_version=$(wingbits -v | grep -oP '(?<=wingbits version )[^"]*')
echo "Current local version: $local_version"
echo "Current local build: $local_json_version"

SCRIPT_URL="https://gitlab.com/wingbits/config/-/raw/master/download.sh"
JSON_URL="https://install.wingbits.com/$GOOS-$GOARCH.json"
script=$(curl -s $SCRIPT_URL)
version=$(echo "$script" | grep -oP '(?<=WINGBITS_CONFIG_VERSION=")[^"]*')
script_json=$(curl -s $JSON_URL)
json_version=$(echo "$script_json" | jq -r '.Version')

echo "Latest available Wingbits version: $version"
echo "Latest available Wingbits build: $json_version"

if [ "$version" != "$local_version" ] || [ "$json_version" != "$local_json_version" ] || [ -z "$json_version" ] || [ -z "$version" ]; then
    echo "WARNING: You are not running the latest Wingbits version. Updating..."
    echo "Architecture: $GOOS-$GOARCH"
    rm -rf $WINGBITS_PATH/wingbits.gz
    curl -s -o $WINGBITS_PATH/wingbits.gz "https://install.wingbits.com/$json_version/$GOOS-$GOARCH.gz"
    rm -rf $WINGBITS_PATH/wingbits
    gunzip $WINGBITS_PATH/wingbits.gz
    chmod +x $WINGBITS_PATH/wingbits
    echo "$version" > $WINGBITS_VERSION_PATH/version
    echo "$json_version" > $WINGBITS_VERSION_PATH/json-version
    echo "New Wingbits version installed: $version"
    echo "New Wingbits build installed: $json_version"
else
    echo "Wingbits is up to date"
fi

# Variables are verified – continue with startup procedure.

# Place correct station ID in /etc/wingbits/device
echo -E "${WINGBITS_DEVICE_ID}" > $WINGBITS_VERSION_PATH/device

# Start wingbits feeder and put in the background.
wingbits feeder start 2>&1 | stdbuf -o0 sed --unbuffered '/^$/d' |  awk -W interactive '{print "[wingbits-feeder]     " $0}' &

# Wait for any services to exit.
wait -n