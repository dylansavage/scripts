#!/bin/bash

encryptedFile=$1
title=${1%%.*}
privateKey=$2
publicKey=$3


# Decrypts the encrypted tar file
/bin/openssl smime -decrypt -in "$encryptedFile" -binary -inform DEM -inkey "$privateKey" -out "$title".tar.gz

# Untars the original file with the signature
/bin/tar -xf "$title".tar.gz 

# Creates an array of all the untarred files 
myFiles=("$title"*)

# Finds the orignial full name of the file
for file in "${myFiles[@]}"; do
	if [[ ! "$file" =~ \(*.tar*\|*.sig\) ]]; then
	originalFile="${file}"
	fi
done

/bin/tar/echo "$originalFile"

# Verifies the file against the included signature
/bin/openssl dgst -sha256 -verify  <(openssl x509 -in "$publicKey"  -pubkey -noout) -signature "$title".sig "$originalFile" 


