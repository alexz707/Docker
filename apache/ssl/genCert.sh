#!/bin/bash
###############################################################################
# Set default params
###############################################################################
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
EXTFILE="$SCRIPT_DIR/cert_ext.cnf"
SERVER_KEY="$SCRIPT_DIR/keys/server.key"
SERVER_CRT="$SCRIPT_DIR/keys/server.crt"
OPENSSL_CMD="/usr/bin/openssl"
###############################################################################
# Script entry point
###############################################################################
echo -e "Generating private key"
$OPENSSL_CMD req -x509 -nodes -newkey rsa -days 1000 -keyout $SERVER_KEY -out $SERVER_CRT -config $EXTFILE 2>/dev/null
if [ $? -ne 0 ] ; then
   echo -e "ERROR: Failed to generate keys!"
   exit 1
fi
