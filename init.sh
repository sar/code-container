#!/bin/sh

which code-server

code-server \
  --disable-telemetry \
  --cert=/config/certs/ssl.crt \
  --cert-key=/config/certs/ssl.key \
  --config=/config/config.yaml \
  --user-data-dir=/config/data \
  --extensions-dir=/config/extensions

set +x;
