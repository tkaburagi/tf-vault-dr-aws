#!/bin/bash

PRV_IP_0=10.10.0.50
PRV_IP_1=10.10.1.50
CA_CERT=$(cat /Users/kabu/hashicorp/certs/vaultca-hashidemos.crt.pem)
CLIENT_CERT=$(cat /Users/kabu/hashicorp/certs/vaultvault-hashidemos.crt.pem)
CLIENT_KEY=$(cat /Users/kabu/hashicorp/certs/vaultvault-hashidemos.key.pem)
DR_1_URL=https://vault-dr-0.kabu.hashidemos.io
DR_2_URL=https://vault-dr-1.kabu.hashidemos.io
TAG=kabu_vault_eip

PUB_IP_0=$(
  aws ec2 describe-addresses \
        --filters "Name=tag-key,Values=Name" \
                  "Name=tag-value,Values=${TAG}" \
        | jq '.Addresses | sort_by(.PrivateIpAddress)' \
        | jq -r '.[0].PublicIp'
  )

echo "PUB_IP_0: "${PUB_IP_0}

PUB_IP_1=$(
  aws ec2 describe-addresses \
        --filters "Name=tag-key,Values=Name" \
                  "Name=tag-value,Values=${TAG}" \
        | jq '.Addresses | sort_by(.PrivateIpAddress)' \
        | jq -r '.[1].PublicIp'
  )

echo "PUB_IP_1: "${PUB_IP_1}

# Init Learder 1
echo "# Init Learder 1"
ssh -i ~/.ssh/hashistack.pem ubuntu@${PUB_IP_0} \
  -o "StrictHostKeyChecking no" \
  VAULT_ADDR=https://${PRV_IP_0}:8200 ./vault operator init -format=json -tls-skip-verify

# Init Learder 2
echo "# Init Learder 2"
ssh -i ~/.ssh/hashistack.pem ubuntu@${PUB_IP_1} \
  -o "StrictHostKeyChecking no" \
  VAULT_ADDR=https://${PRV_IP_1}:8200 ./vault operator init -format=json -tls-skip-verify

echo "Enter the Token for Cluster 0"
read VTOKEN_0

echo "########## TOKEN 0: "${VTOKEN_0}

echo "Enter the Token for Cluster 1"
read VTOKEN_1

echo "########## TOKEN 1: "${VTOKEN_1}

# DR Settings
echo "#DR Setting on Primary"
VAULT_TOKEN=${VTOKEN_0} \
vault write -f -tls-skip-verify \
-address=${DR_0_URL} \
sys/replication/dr/primary/enable

WRAPPING_TOKEN=$(
  VAULT_TOKEN=${VTOKEN_0}  \
  vault write -f  -format=json -tls-skip-verify \
  -address=${DR_0_URL} \
  sys/replication/dr/primary/secondary-token \
  id="secondary" | jq -r '.wrap_info.token'
)

echo "#DR Setting on Secondary"

VAULT_TOKEN=${VTOKEN_1} \
vault write -f -tls-skip-verify \
-address=${DR_1_URL} \
sys/replication/dr/secondary/enable \
token=${WRAPPING_TOKEN}

sleep 60

# Check DR Status
echo "#### DR0 Status"
VAULT_TOKEN=${VTOKEN_0} vault read -tls-skip-verify \
-address=${DR_0_URL} \
sys/replication/dr/status

echo "#### DR1 Status"
VAULT_TOKEN=${VTOKEN_1} vault read -tls-skip-verify \
-address=${DR_1_URL} \
sys/replication/dr/status

# Check Node Status
echo "#### NODE0 STATUS"
VAULT_TOKEN=${VTOKEN_0} vault status -tls-skip-verify \
-address=${DR_0_URL}

echo "#### NODE1 STATUS"
ssh -i ~/.ssh/hashistack.pem ubuntu@${PUB_IP_1} \
VAULT_TOKEN=${VTOKEN_1} vault status -tls-skip-verify \
-address=${DR_1_URL}