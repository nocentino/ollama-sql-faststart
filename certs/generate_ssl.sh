#!/bin/sh

if [ ! -f /certs/nginx.key ] || [ ! -f /certs/nginx.crt ]; then
  echo "Generating SSL certificates..."
  openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout /certs/nginx.key -out /certs/nginx.crt \
    -config /tmp/certs/openssl.cnf
  echo "Generated SSL certificates..."
else
  echo "SSL certificates already exist. Skipping generation."
fi
