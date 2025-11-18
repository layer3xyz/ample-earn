# Ample Deployment Scripts

This directory contains deployment scripts for the Ample Money protocol.

## Scripts

### Deploy.s.sol

Deploys the Ample Money contracts:

1. **AmpleEarnFactory** - Factory contract for creating AmpleEarn vaults
2. **AmpleEarn** (optional) - Individual vault created via the factory
3. **AmpleDraw** - Automatically deployed alongside AmpleEarn

### GenerateMerkleRoot.s.sol

Generates Merkle roots and proofs for prize distribution testing.

## Chain Configuration

Chain-specific configurations are stored in `script/ample/config/*.sol`:

- **Mainnet.sol** - Ethereum Mainnet (Chain ID: 1)
- **Sepolia.sol** - Sepolia Testnet (Chain ID: 11155111)
- **Base.sol** - Base Mainnet (Chain ID: 8453)
- **Arbitrum.sol** - Arbitrum One (Chain ID: 42161)
- **Optimism.sol** - Optimism Mainnet (Chain ID: 10)
- **Localhost.sol** - Local testnet (Chain ID: 31337)

Each config includes:

- EVC, Permit2, and Perspective addresses
- Chainlink VRF Coordinator and Key Hash
- Default VRF callback gas limit and confirmations

**To add support for a new chain:** Create a new config file following the existing pattern.

## Setup

1. Copy the example environment file:

```bash
cp .env.example .env
```

2. Fill in the required variables in `.env`:

### Required for Deployment

```env
# Deployer
DEPLOYER_ADDRESS=0x...  # or use MNEMONIC for testing
```

### Additional Variables for Vault Creation

```env
CREATE_VAULT=true
VAULT_OWNER=0x...              # Defaults to deployer
TIMELOCK=604800                # 7 days in seconds
ASSET=0x...                    # Underlying asset (e.g., USDC)
VAULT_NAME="Ample USDC"
VAULT_SYMBOL="aUSDC"
VRF_SUBSCRIPTION_ID=123        # Get from vrf.chain.link
```

## Usage

### Deploy Factory Only

Using justfile:

```bash
# Dry run (simulation)
just deploy-factory --rpc-url $RPC_URL

# Broadcast transaction
just deploy-factory --rpc-url $RPC_URL --broadcast

# Verify on Etherscan
just deploy-factory --rpc-url $RPC_URL --broadcast --verify
```

Using forge directly:

```bash
forge script script/ample/Deploy.s.sol --rpc-url $RPC_URL --broadcast
```

### Deploy Factory + Vault

Using justfile:

```bash
# Dry run (simulation)
just deploy-vault --rpc-url $RPC_URL

# Broadcast transaction
just deploy-vault --rpc-url $RPC_URL --broadcast
```

Using forge directly:

```bash
CREATE_VAULT=true forge script script/ample/Deploy.s.sol --rpc-url $RPC_URL --broadcast
```

### Local Development

Deploy to local Anvil testnet:

```bash
# Start Anvil in another terminal
anvil

# Deploy factory only
just deploy-local

# Deploy factory + vault
just deploy-vault-local
```

## Justfile Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `deploy-factory` | `df` | Deploy AmpleEarnFactory |
| `deploy-vault` | `dv` | Deploy factory and create vault |
| `deploy-local` | `dl` | Deploy factory to local testnet |
| `deploy-vault-local` | `dvl` | Deploy vault to local testnet |
| `generate-merkle` | `gm` | Generate merkle root for testing |

## Example Deployments

### Sepolia Testnet

```bash
# Set environment variables
export DEPLOYER_ADDRESS=0x...
export CREATE_VAULT=true
export ASSET=0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238  # USDC on Sepolia
export VAULT_NAME="Ample USDC"
export VAULT_SYMBOL="aUSDC"
export VRF_SUBSCRIPTION_ID=123  # Your Chainlink subscription

# Deploy
forge script script/ample/Deploy.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

### Base Mainnet

```bash
# Set environment variables
export DEPLOYER_ADDRESS=0x...
export CREATE_VAULT=true
export ASSET=0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913  # USDC on Base
export VAULT_NAME="Ample USDC"
export VAULT_SYMBOL="aUSDC"
export VRF_SUBSCRIPTION_ID=456  # Your Chainlink subscription

# Deploy
forge script script/ample/Deploy.s.sol \
  --rpc-url $BASE_RPC_URL \
  --broadcast \
  --verify
```

## Updating Chain Configurations

If you need to update protocol addresses (EVC, Perspective) or VRF settings for a specific chain:

1. Edit the appropriate config file in `script/ample/config/`
2. Update the addresses/settings
3. Commit the changes

Example:

```solidity
// script/ample/config/Sepolia.sol
function getConfig() internal pure returns (ChainConfig memory) {
    return ChainConfig({
        evc: 0x...,              // Update this
        permit2: 0x...,          // Or this
        evkFactoryPerspective:0x...,      // Or this
        vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
        vrfKeyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
        vrfCallbackGasLimit: 500_000,
        vrfRequestConfirmations: 3
    });
}
```

## Verification

After deployment, verify contracts on block explorer:

```bash
forge verify-contract \
  --chain-id $CHAIN_ID \
  --constructor-args $(cast abi-encode "constructor(address,address,address,address)" $OWNER $EVC $PERMIT2 $PERSPECTIVE) \
  $FACTORY_ADDRESS \
  src/ample/AmpleEarnFactory.sol:AmpleEarnFactory \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

## Chainlink VRF Setup

Before creating a vault, you need a Chainlink VRF subscription:

1. Go to [vrf.chain.link](https://vrf.chain.link)
2. Connect your wallet to the target network
3. Create a new subscription
4. Fund it with LINK tokens
5. Add the deployed AmpleDraw contract as a consumer
6. Use the subscription ID in your `.env` file

## Security

- Never commit `.env` files
- Use hardware wallets for mainnet deployments
- Verify all addresses before deployment
- Test on testnets first
- Review chain configs and deployment parameters carefully
- Ensure Chainlink VRF subscription is funded before drawing prizes
