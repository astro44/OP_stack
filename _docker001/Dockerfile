# Use Ubuntu as the base image based on ARM64 architecture
from ubuntu:latest

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install Python and other dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    git \
    make \
    jq \
    curl \
    wget \
    nodejs \
    npm \
    xz-utils \
    direnv \
    && ln -s /usr/bin/python3 /usr/bin/python \
    && rm -rf /var/lib/apt/lists/*


# install rust and tools
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y \
    && . $HOME/.cargo/env \
    && rustup toolchain install nightly \
    && rustup default nightly \
    && rustup target add wasm32-unknown-unknown --toolchain nightly

# ::::FOUNDRY::::
# Foundry installation for now
RUN curl -L https://foundry.paradigm.xyz | bash
ENV PATH="/root/.foundry/bin:${PATH}"
RUN foundryup

# Install Node.js (latest v16 release)  16.20.0
ENV NODE_VERSION 20.10.0
RUN wget https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-arm64.tar.xz \
    && tar -xJf node-v${NODE_VERSION}-linux-arm64.tar.xz -C /usr/local --strip-components=1 \
    && rm -f node-v${NODE_VERSION}-linux-arm64.tar.xz

ENV GO_VERSION 1.21.4
RUN wget https://go.dev/dl/go${GO_VERSION}.linux-arm64.tar.gz \
    && tar -xvf go${GO_VERSION}.linux-arm64.tar.gz \
    && mv go /usr/local \
    && rm go${GO_VERSION}.linux-arm64.tar.gz
ENV PATH $PATH:/usr/local/go/bin

# Install pnpm
RUN npm install -g pnpm --verbose

# Clone and setup Optimism
RUN git clone https://github.com/ethereum-optimism/optimism.git \
    && cd optimism \
    && pnpm install \
    && cd ../

# The below is the most problematic part of the build.  It takes a long time and often fails.
# make NODE BATCHER PROPOSER
RUN cd optimism \
    && make VERBOSE=1 op-node op-batcher op-proposer \
    && pnpm build \
    && cd ../

# Clone and setup op-geth
RUN git clone https://github.com/ethereum-optimism/op-geth.git \
    && cd op-geth \
    && make geth \
    && cd ../

# Declare arguments
ARG GS_ADMIN_ADDRESS
ARG GS_ADMIN_PRIVATE_KEY
ARG GS_BATCHER_ADDRESS
ARG GS_BATCHER_PRIVATE_KEY
ARG GS_PROPOSER_ADDRESS
ARG GS_PROPOSER_PRIVATE_KEY
ARG GS_SEQUENCER_ADDRESS
ARG GS_SEQUENCER_PRIVATE_KEY
ARG L1_RPC_URL
ARG L1_RPC_KIND
ARG DEPLOYMENT_CONTEXT
ARG IMPL_SALT

# Set environment variables
ENV GS_ADMIN_ADDRESS=$GS_ADMIN_ADDRESS
ENV GS_ADMIN_PRIVATE_KEY=$GS_ADMIN_PRIVATE_KEY
ENV GS_BATCHER_ADDRESS=$GS_BATCHER_ADDRESS
ENV GS_BATCHER_PRIVATE_KEY=$GS_BATCHER_PRIVATE_KEY
ENV GS_PROPOSER_ADDRESS=$GS_PROPOSER_ADDRESS
ENV GS_PROPOSER_PRIVATE_KEY=$GS_PROPOSER_PRIVATE_KEY
ENV GS_SEQUENCER_ADDRESS=$GS_SEQUENCER_ADDRESS
ENV GS_SEQUENCER_PRIVATE_KEY=$GS_SEQUENCER_PRIVATE_KEY
ENV L1_RPC_URL=$L1_RPC_URL
ENV L1_RPC_KIND=$L1_RPC_KIND
ENV DEPLOYMENT_CONTEXT=$DEPLOYMENT_CONTEXT
ENV IMPL_SALT=$IMPL_SALT

# Copy the entrypoint script will run in cd optimism via sh
COPY entrypoint.sh /entrypoint.sh
COPY generate_jwt.sh /generate_jwt.sh

RUN chmod +x /entrypoint.sh \
    && ./entrypoint.sh varsOnly

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# direnv doesn't seem to work in docker... use source instead found in entrypoint.sh
RUN cd /optimism \
    && output=$(direnv allow) && echo "Output of direnv allow: $output" \
    && echo "DEPLOYMENT_CONTEXT: $DEPLOYMENT_CONTEXT" \
    && echo "L1_RPC_KIND: $L1_RPC_KIND" \
    && echo "GS_PROPOSER_ADDRESS: $GS_PROPOSER_ADDRESS" \
    && echo "L1_RPC_URL: $L1_RPC_URL" \
    && echo "IMPL_SALT: $IMPL_SALT" \
    && cd /

# SETUP config files
RUN cd /optimism \
    && ls .en* \
    && cat .envrc \
    && cd ./packages/contracts-bedrock \
    && ./scripts/getting-started/config.sh \
    # && cd dude \
    && cd /

# DEPLOY CONTRACTS  direnv allow will generate new salt each time.
RUN cd /optimism/packages/contracts-bedrock \
    && forge script scripts/Deploy.s.sol:Deploy --private-key $GS_ADMIN_PRIVATE_KEY --broadcast --rpc-url $L1_RPC_URL

RUN cd /optimism/packages/contracts-bedrock \
    && ls . \
    && forge script scripts/Deploy.s.sol:Deploy --sig 'sync()' --rpc-url $L1_RPC_URL

# Generate the L2 config files
RUN cd /optimism \
    && cd op-node \
    && go run cmd/main.go genesis l2 \
    --deploy-config ../packages/contracts-bedrock/deploy-config/getting-started.json \
    --deployment-dir ../packages/contracts-bedrock/deployments/getting-started/ \
    --outfile.l2 genesis.json \
    --outfile.rollup rollup.json \
    --l1-rpc $L1_RPC_URL

# RUN openssl rand from sh file since docker shell isn't dynamic
RUN /generate_jwt.sh \
    && cp /jwt.txt /op-geth \
    && cp /jwt.txt /optimism/op-node \
    && cp /optimism/op-node/genesis.json /op-geth

RUN cd /op-geth \
    && mkdir datadir \
    && build/bin/geth init --datadir=datadir genesis.json

# Set the working directory
# WORKDIR /optimism

# Expose necessary ports (if any)
# EXPOSE <port>

# Command to run the application
# CMD ["your_command_here"]
# docker run -d -p 8551:8551 -p 8547:8547 -p 8545:8545 optimism-env op-node op-batcher

# docker run -d --name op-geth --network="host" -p 8545:8545 optimism-env op-geth
# docker run -d --name op-geth --network="host" optimism-env op-geth
# docker run -d --name op-node --network="host" -p 8547:8547 optimism-env op-node
# docker run -d --name op-node --network="host" optimism-env op-node
# docker run -d --name op-batcher -p 8548:8548 optimism-env op-batcher
# docker run -d --name op-proposer -p 8560:8560 optimism-env op-proposer

# docker run -d --name optimism-services -p 8547:8547 -p 8548:8548 -p 8560:8560 optimism-env op-node op-batcher op-proposer


# docker run -d --name optimism-services -p 8547:8547 -p 8548:8548 -p 8560:8560 optimism-env op-node op-batcher op-proposer

# docker run -d --name optimism-all --network="host" optimism-env op-geth op-node op-batcher op-proposer

# docker run -d --name op-batcher --network="host" optimism-env op-batcher
# docker run -d --name op-proposer --network="host" optimism-env op-proposer
