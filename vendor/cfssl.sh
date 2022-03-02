#!/bin/sh
cfssl gencert -initca nokia.json | cfssljson -bare ca -
mkdir ../trust
openssl x509 -in ca.pem -inform PEM -out '../trust/Nokia Vendor CA.crt' -outform DER
