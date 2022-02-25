#!/bin/sh

if [[ $(which openssl) != "/usr/bin/openssl" ]]
    then
        printf "OpenSSL not installed, distribution agnostic package required."
        exit 125
fi

openssl req \
  -nodes \
  -new \
  -x509 \
  -keyout ssl.key \
  -out ssl.crt \
  -subj '/CN=localhost/O=code/C=US'

set +x
