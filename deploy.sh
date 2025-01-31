#!/bin/bash
set -euo pipefail

if [ ! -f .env ]; then
    echo "Error: .env file not found"
    exit 1
fi

source .env

if [ -z "${PRIVATE_KEY:-}" ]; then
    echo "Error: PRIVATE_KEY not set in .env"
    exit 1
fi

forge script script/Deploy.s.sol:DeployTimeWeightedStaking \
  --rpc-url odyssey \
  --private-key ${PRIVATE_KEY} \
  --broadcast \
  --verify \
  --verifier blockscout \
  --verifier-url https://odyssey-explorer.ithaca.xyz/api/