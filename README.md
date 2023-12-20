
# Initial Setup - this is not regularly maintained and should be considered a starting/learning point.
  see https://docs.optimism.io/builders/chain-operators/tutorials/create-l2-rollup
   More info:
  - https://discord.gg/optimism
  - https://github.com/ethereum-optimism/developers/discussions
## INSTALLATION from folder _docker001

### make sure to add in the wallets and other details into the .env file first

see you have the correct version:
https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/scripts/getting-started/versions.sh

get new wallets:
https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/scripts/getting-started/wallets.sh


## RUN the following in bash IN the _docker001 dir:
- cd _docker001
- `./build.sh`  to build
- `docker-compose -p op-stack up op-services -d` to run in prompt
## OR....
## RUN the following for Child node
- `docker-compose -p op-stack up op-node -d`


### Swap out the IMPL_SALT value before every new "chain" build!
use the below to get a new value:
``` bash
    echo (openssl rand -hex 32)
```
#### If you see:
``` bash
    nondescript error that includes EvmError: Revert and Script failed \
    then you likely need to change the IMPL_SALT environment variable. \
    This variable determines the addresses of various smart contracts that \
     are deployed via CREATE2. If the same IMPL_SALT is used to deploy the \
     same contracts twice, the second deployment will fail. You can generate \
     a new IMPL_SALT by running direnv allow anywhere in the Optimism Monorepo.
```


### We recommend funding the accounts with the following amounts when using Sepolia:
- Admin — 0.2 ETH
- Proposer — 0.2 ETH
- Batcher — 0.1 ETH
