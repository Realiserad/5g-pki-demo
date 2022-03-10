#!/bin/sh

curl -L -s https://github.com/moparisthebest/static-curl/releases/download/v7.82.0/curl-amd64 --output curl
chmod +x ./curl
curl -L -s https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 --output jq
chmod +x ./jq
