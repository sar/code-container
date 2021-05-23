#!/bin/bash

if [[ $(which openssl) != "/usr/bin/openssl" ]]
    then
        printf "OpenSSL not installed, distribution agnostic package required."
        exit 125
fi

openssl req -new > ssl.csr
openssl rsa -in privkey.pem -out ssl.key
openssl x509 -in ssl.csr -out ssl.crt -req -signkey ssl.key

set +x
