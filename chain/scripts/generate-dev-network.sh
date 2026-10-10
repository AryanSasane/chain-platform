#!/usr/bin/env bash
# Generates a fresh dev QBFT network: genesis + 4 validator keys.
# Output goes to secrets/dev/ (gitignored). Re-running WIPES the old network.
set -euo pipefail
cd "$(dirname "$0")/../.."

BESU_VERSION=$(grep '^BESU_VERSION=' .env.example | cut -d= -f2)
OUT=secrets/dev
TMP=secrets/networkFiles

rm -rf "$OUT" "$TMP"

docker run --rm --user "$(id -u):$(id -g)" \
  -v "$(pwd)":/work -w /work \
  "hyperledger/besu:${BESU_VERSION}" \
  operator generate-blockchain-config \
  --config-file=/work/chain/networks/dev/qbft-config.json \
  --to=/work/"$TMP" \
  --private-key-file-name=key

mkdir -p "$OUT"
cp "$TMP/genesis.json" "$OUT/genesis.json"

i=1
for d in "$TMP"/keys/*/; do
  mkdir -p "$OUT/validator$i"
  cp "$d/key" "$d/key.pub" "$OUT/validator$i/"
  i=$((i+1))
done

rm -rf "$TMP"
echo "Done. Generated $((i-1)) validators in $OUT/"

PUB=$(tr -d '\n' < "$OUT/validator1/key.pub" | sed 's/^0x//')
echo "BOOTNODE_ENODE=enode://${PUB}@172.30.0.11:30303" > "$OUT/bootnode.env"
echo "Wrote $OUT/bootnode.env"
