#!/usr/bin/env bash
# Generates a fresh dev QBFT network: genesis + 4 validator keys.
# Output goes to secrets/dev/ (gitignored). Re-running WIPES the old network.
set -euo pipefail
cd "$(dirname "$0")/../.."

BESU_VERSION=$(grep '^BESU_VERSION=' .env.example | cut -d= -f2)
OUT=secrets/dev
TMP=secrets/networkFiles

rm -rf "$OUT" "$TMP"
# Besu will not create missing parent directories
mkdir -p "$OUT"

docker run --rm --user "$(id -u):$(id -g)" \
  -v "$(pwd)":/work -w /work \
  "hyperledger/besu:${BESU_VERSION}" \
  operator generate-blockchain-config \
  --config-file=/work/chain/networks/dev/qbft-config.json \
  --to=/work/"$TMP" \
  --private-key-file-name=key

cp "$TMP/genesis.json" "$OUT/genesis.json"

i=1
for d in "$TMP"/keys/*/; do
  mkdir -p "$OUT/validator$i"
  cp "$d/key" "$d/key.pub" "$OUT/validator$i/"
  i=$((i+1))
done

rm -rf "$TMP"
echo "Done. Generated $((i-1)) validators in $OUT/"

# Every validator dials every other one directly, so the mesh does not depend on discovery
for n in $(seq 1 $((i-1))); do
  PUB=$(tr -d '\n' < "$OUT/validator$n/key.pub" | sed 's/^0x//')
  echo "\"enode://${PUB}@172.30.0.1$n:30303\""
done | paste -sd, | sed 's/^/[/; s/$/]/' > "$OUT/static-nodes.json"
echo "Wrote $OUT/static-nodes.json"

# Only applies on Grafana's first start; make reset wipes its volume too, so they stay in step
echo "GF_SECURITY_ADMIN_PASSWORD=$(openssl rand -hex 16)" > "$OUT/grafana.env"
echo "Wrote $OUT/grafana.env"
