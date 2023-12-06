# Initial Setup
  see https://stack.optimism.io/docs/build/getting-started/#configure-your-network
   More info: 
  - https://discord.gg/optimism
  - https://github.com/ethereum-optimism/developers/discussions
## INSTALLATION from folder _docker001

### make sure to add in the wallets and other details into the .env file first

see you have the correct version:
https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/scripts/getting-started/versions.sh

get new wallets:
https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/scripts/getting-started/wallets.sh


#### run the following in bash:
- `./build.sh`  to build
- `./build.sh test` to run in prompt

### Swap out the IMPL_SALT value before every build!
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
