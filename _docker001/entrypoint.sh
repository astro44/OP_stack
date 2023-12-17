#!/bin/bash

init_vars(){
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
export L2_CHAIN_ID=$L2_CHAIN_ID
export L2_BLOCK_TIME=$L2_BLOCK_TIME
export L2_FINALIZE_PERIOD=$L2_FINALIZE_PERIOD
export L2_GOV_SYMBOL=$L2_GOV_SYMBOL
export L2_GOV_NAME=$L2_GOV_NAME
export L1_RPC_URL=$L1_RPC_URL
export L1_RPC_KIND=$L1_RPC_KIND
export DEPLOYMENT_CONTEXT=$DEPLOYMENT_CONTEXT
export IMPL_SALT=$IMPL_SALT
export EPOCH_SECS_INIT=$EPOCH_SECS_INIT
EOF
  # export IMPL_SALT=\$(openssl rand -hex 32)
  # Source the .envrc file
  # NOT NEEDED AS COMPOSER WILL SET ENV VARS
  # source .envrc
}

modules_started=0
# Function to start op-geth
start_op_geth() {
  init_vars;
  cd /op-geth
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
      --networkid=$L2_CHAIN_ID \
      --authrpc.vhosts="*" \
      --authrpc.addr=0.0.0.0 \
      --authrpc.port=8551 \
      --authrpc.jwtsecret=./jwt.txt \
      --rollup.disabletxpoolgossip=true \
      &
  modules_started=1
}

# Function to start op-node
start_op_node() {
  init_vars;
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
  modules_started=1
}

# Function to start op-batcher
start_op_batcher() {
  init_vars;
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
  modules_started=1
}


# Function to start op-proposer
start_op_proposer() {
  init_vars;
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
  modules_started=1
}

child_init_node(){
  cd /
  ./generate_jwt.sh
  cp /jwt.txt /op-geth
  cp /jwt.txt /optimism/op-node
  cp /optimism/op-node/genesis.json /op-geth
  cd /op-geth
  build/bin/geth init --datadir=datadir genesis.json
}

child_start_node(){
  cd /optimism/op-node
    #   --p2p.static=<nodes> \  too accomplish this we'll need to
    # --p2p.listen.ip=0.0.0.0 \
    # --p2p.listen.tcp=9003 \
    # --p2p.listen.udp=9003 \
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
    --p2p.static=<nodes> \
    --p2p.listen.ip=0.0.0.0 \
    --p2p.listen.tcp=9003 \
    --p2p.listen.udp=9003 \
    --rpc.enable-admin \
    --p2p.sequencer.key=$GS_SEQUENCER_PRIVATE_KEY \
    --l1=$L1_RPC_URL \
    --l1.rpckind=$L1_RPC_KIND \
      &
  modules_started=1
}


if [ $# -eq 0 ]; then
  # start long processes
  echo "No arguments provided. ..nothing to do...shutting down..."
  exit 0
else
  for arg in "$@"
  do
      case $arg in
          child-init)
              child_init_node
              ;;
          op-geth)
              start_op_geth
              ;;
          op-node)
              start_op_node
              ;;
          op-batcher)
              start_op_batcher
              ;;
          op-proposer)
              start_op_proposer
              ;;
          varsOnly)
              init_vars
              echo "vars only..."
              exit 0
              ;;
          *)
              echo "Invalid argument: $arg"
              ;;
       esac
   done
  cd /
  if [ $modules_started -eq 1 ]; then
      # Keep the script running if any modules were started
      tail -f /dev/null
  else
      # Exit if no modules were started
      echo "No valid modules were started. Exiting."
      exit 0
  fi

fi

# docker run -d optimism-stack op-geth op-node op-batcher