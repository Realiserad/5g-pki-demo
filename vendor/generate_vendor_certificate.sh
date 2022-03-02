#!/bin/sh
cd /vendor
openssl req \
    -newkey rsa:3072 \
    -nodes \
    -subj "/CN=$(hostname)/O=Nokia/C=FI" \
    -keyout vendor_key.pem \
    -out vendor_csr.pem
openssl x509 \
    -req \
    -days 5478 \
    -set_serial 01 \
    -extfile extensions.conf \
    -in vendor_csr.pem \
    -out vendor_cert.pem \
    -CA ca.pem \
    -CAkey ca-key.pem