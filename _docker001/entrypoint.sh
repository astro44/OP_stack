#!/bin/bash
cd optimism
# Write environment variables to .envrc
cat <<EOF > .envrc
export GS_ADMIN_ADDRESS=$GS_ADMIN_ADDRESS
export GS_ADMIN_PRIVATE_KEY=$GS_ADMIN_PRIVATE_KEY
export GS_BATCHER_ADDRESS=$GS_BATCHER_ADDRESS
export GS_BATCHER_PRIVATE_KEY=$GS_BATCHER_PRIVATE_KEY
export GS_PROPOSER_ADDRESS=$GS_PROPOSER_ADDRESS
export GS_PROPOSER_PRIVATE_KEY=$GS_PROPOSER_PRIVATE_KEY
export GS_SEQUENCER_ADDRESS=$GS_SEQUENCER_ADDRESS
export GS_SEQUENCER_PRIVATE_KEY=$GS_SEQUENCER_PRIVATE_KEY
export L1_RPC_URL=$L1_RPC_URL
export L1_RPC_KIND=$L1_RPC_KIND
export DEPLOYMENT_CONTEXT=$DEPLOYMENT_CONTEXT
export IMPL_SALT=\$(openssl rand -hex 32)
EOF

# Source the .envrc file
source .envrc

if [ $# -eq 0 ]; then
  # start long processes
  cd /optimism/op-geth
  # START OP-GETH
  ./build/bin/geth \
      --datadir ./datadir \
      --http \
      --http.corsdomain="*" \
      --http.vhosts="*" \
      --http.addr=0.0.0.0 \
      --http.api=web3,debug,eth,txpool,net,engine \
      --ws \
      --ws.addr=0.0.0.0 \
      --ws.port=8546 \
      --ws.origins="*" \
      --ws.api=debug,eth,txpool,net,engine \
      --syncmode=full \
      --gcmode=archive \
      --nodiscover \
      --maxpeers=0 \
      --networkid=42069 \
      --authrpc.vhosts="*" \
      --authrpc.addr=0.0.0.0 \
      --authrpc.port=8551 \
      --authrpc.jwtsecret=./jwt.txt \
      --rollup.disabletxpoolgossip=true


  cd /optimism/op-node
  # START OP-NODE
  ./bin/op-node \
    --l2=http://localhost:8551 \
    --l2.jwt-secret=./jwt.txt \
    --sequencer.enabled \
    --sequencer.l1-confs=5 \
    --verifier.l1-confs=4 \
    --rollup.config=./rollup.json \
    --rpc.addr=0.0.0.0 \
    --rpc.port=8547 \
    --p2p.disable \
    --rpc.enable-admin \
    --p2p.sequencer.key=$GS_SEQUENCER_PRIVATE_KEY \
    --l1=$L1_RPC_URL \
    --l1.rpckind=$L1_RPC_KIND \
      &

  cd /optimism/op-batcher
  # START OP-BATCHER
  ./bin/op-batcher \
      --l2-eth-rpc=http://localhost:8545 \
      --rollup-rpc=http://localhost:8547 \
      --poll-interval=1s \
      --sub-safety-margin=6 \
      --num-confirmations=1 \
      --safe-abort-nonce-too-low-count=3 \
      --resubmission-timeout=30s \
      --rpc.addr=0.0.0.0 \
      --rpc.port=8548 \
      --rpc.enable-admin \
      --max-channel-duration=1 \
      --l1-eth-rpc=$L1_RPC_URL \
      --private-key=$GS_BATCHER_PRIVATE_KEY \
      &

  cd /optimism/op-proposer
  # START OP-PROPOSER
  ./bin/op-proposer \
      --poll-interval=12s \
      --rpc.port=8560 \
      --rollup-rpc=http://localhost:8547 \
      --l2oo-address=$(cat ../packages/contracts-bedrock/deployments/getting-started/L2OutputOracleProxy.json | jq -r .address) \
      --private-key=$GS_PROPOSER_PRIVATE_KEY \
      --l1-eth-rpc=$L1_RPC_URL \
      &

  tail -f /dev/null
else
  # Execute the main container command
  # exec "$@"
  exit 0
fi

