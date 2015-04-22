#!/bin/bash
 
KEY_NAME=$1
PEM_NAME="${KEY_NAME}-key.pem"
PEM_NAME_PCKS8="${KEY_NAME}-pem-PCKS8-format.pem"
CERTIFICATE_NAME="${KEY_NAME}-certificate.pem"
openssl genrsa 2048 > $PEM_NAME
openssl pkcs8 -topk8 -nocrypt -inform PEM -in $PEM_NAME -out $PEM_NAME_PCKS8
openssl req -new -x509 -nodes -sha1 -days 365 -key $PEM_NAME -outform PEM > $CERTIFICATE_NAME 
