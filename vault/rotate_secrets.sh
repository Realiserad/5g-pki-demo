#!/bin/sh

# Rotates the shared secret of all CMP aliases in EJBCA and pushes 
# the new secrets to /ran/data/<alias> in HashiCorp Vault.
#
# Requires curl and jq on the path.

VAULT_ADDR=http://vault:8200
EJBCA_CLI=/opt/primekey/bin/ejbca.sh

if [ -f "/var/run/secrets/kubernetes.io/serviceaccount/token" ]; then
  echo "Attempting to fetch token using Kubernetes service account."
  KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
  VAULT_TOKEN=$(curl -s \
    -X POST \
    -d '{
          "jwt": "'"$KUBE_TOKEN"'",
          "role": "rw"
        }' 
    $VAULT_ADDR/v1/auth/ejbca/login | jq -r '.auth.client_token')
fi

if [ "$VAULT_TOKEN" = "token" ]; then
  echo "Dummy token detected, creating mount point."
  curl -s \
    -X POST \
    -H "X-Vault-Request: true" \
    -H "X-Vault-Token: $VAULT_TOKEN" \
    -d '{
          "type": "kv-v2",
          "description": "", 
          "config": {
            "options": null,
            "default_lease_ttl": "0s",
            "max_lease_ttl": "0s",
            "force_no_cache": false
          },
          "local": false,
          "seal_wrap": false,
          "external_entropy_access": false,
          "options": null
        }' \
    "$VAULT_ADDR/v1/sys/mounts/ran"
fi

aliases=$($EJBCA_CLI config cmp listalias | awk -F ' ' '{print $6}')
for alias in $aliases; do
  if [ "$($EJBCA_CLI config cmp dumpalias --alias "$alias" | grep authenticationmodule | awk -F ' = ' '{print $2}')" = "HMAC" ]; then
    secret=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c "${1:-32}"; echo;)
    $EJBCA_CLI config cmp updatealias \
      --alias "$alias" \
      --key authenticationparameters \
      --value "$secret"
    curl -s \
      -X PUT \
      -H "X-Vault-Request: true" \
      -H "X-Vault-Token: $VAULT_TOKEN" \
      -d '{
            "data": {
              "secret": "'"$secret"'"
            },
            "options": {}
          }' \
      "$VAULT_ADDR/v1/ran/data/$alias"
    echo "Rotated secret for alias '$alias'."
  fi
done