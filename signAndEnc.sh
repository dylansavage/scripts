#!/bin/bash

unencryptedFile=$1
title=${1%%.*}
privateKey=$2
publicKey=$3


#  Signs the unencypted file
openssl dgst -sha256 -sign "$privateKey" -out "$title".sig "$unencryptedFile"

#  Archive the file with the signature
tar -czf "$title".tar.gz "$unencryptedFile" "$title".sig 

#  Encrypts the archive for sending
openssl smime -encrypt -binary -aes-256-cbc -in "$title".tar.gz -out "$title".tar.gz.enc -outform DER $publicKey

echo "$unencryptedFile ready for transfer" 
