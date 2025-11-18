# Chain Configurations

This directory contains chain-specific deployment configurations for Ample Money.

## Supported Chains

| Chain | Chain ID | Config File | VRF Status |
|-------|----------|-------------|------------|
| Ethereum Mainnet | 1 | `Mainnet.sol` | ✅ Supported |
| Sepolia Testnet | 11155111 | `Sepolia.sol` | ✅ Supported |
| Base | 8453 | `Base.sol` | ✅ Supported |
| Arbitrum One | 42161 | `Arbitrum.sol` | ✅ Supported |
| Optimism | 10 | `Optimism.sol` | ✅ Supported |
| Localhost | 31337 | `Localhost.sol` | 🧪 Mock |

## Configuration Structure

Each chain config includes:

```solidity
struct ChainConfig {
    address evc;                      // Ethereum Vault Connector
    address permit2;                  // Uniswap Permit2 (universal: 0x000000000022D473030F116dDEE9F6B43aC78BA3)
    address perspective;              // Euler Perspective contract
    address vrfCoordinator;           // Chainlink VRF V2.5 Coordinator
    bytes32 vrfKeyHash;              // Gas lane key hash
    uint32 vrfCallbackGasLimit;      // Default: 500,000
    uint16 vrfRequestConfirmations;  // Default: 3
}
```

## Quick Reference

### Ethereum Mainnet

- **Chain ID:** 1
- **VRF Coordinator:** `0xD7f86b4b8Cae7D942340FF628F82735b7a20893a`
- **VRF Key Hash:** `0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef` (200 gwei)
- **Permit2:** `0x000000000022D473030F116dDEE9F6B43aC78BA3`

### Sepolia Testnet

- **Chain ID:** 11155111
- **VRF Coordinator:** `0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B`
- **VRF Key Hash:** `0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae` (30 gwei)
- **Permit2:** `0x000000000022D473030F116dDEE9F6B43aC78BA3`

### Base

- **Chain ID:** 8453
- **VRF Coordinator:** `0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634`
- **VRF Key Hash:** `0x9e9e46732b32662b9adc6f3abdf6c5b926227ab4a99d9d4f669d5eaa4c54e964` (200 gwei)
- **Permit2:** `0x000000000022D473030F116dDEE9F6B43aC78BA3`

### Arbitrum One

- **Chain ID:** 42161
- **VRF Coordinator:** `0x5CE8D5A2BC84beb22a398CCA51996F7930313D61`
- **VRF Key Hash:** `0x1770bdc7eec7771f7ba4ffd640f34260d7f095b79c92d34a5b2551d6f6cfd2be` (150 gwei)
- **Permit2:** `0x000000000022D473030F116dDEE9F6B43aC78BA3`

### Optimism

- **Chain ID:** 10
- **VRF Coordinator:** `0xc0e58B88e64a075C520e6e97a6dD0C27b6A4EC5F`
- **VRF Key Hash:** `0xff0c26aab89482edb69d249785c70e0b4ecf16214807cf6dd88fd7e59b0fb0f8` (200 gwei)
- **Permit2:** `0x000000000022D473030F116dDEE9F6B43aC78BA3`

## TODO: Update Protocol Addresses

The following addresses need to be updated once deployed:

- [ ] **EVC** - Update for each production chain
- [ ] **Perspective** - Update for each production chain

## Adding a New Chain

1. Create a new config file: `script/ample/config/YourChain.sol`
2. Follow the pattern from existing configs
3. Import it in `Deploy.s.sol`
4. Add chain ID check in `_getChainConfig()`
5. Update this README

Example:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import {ChainConfig} from "./ChainConfig.sol";

library YourChainConfig {
    uint256 internal constant CHAIN_ID = 12345;

    function getConfig() internal pure returns (ChainConfig memory) {
        return ChainConfig({
            evc: address(0),
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            evkFactoryPerspective:address(0),
            vrfCoordinator: 0x...,
            vrfKeyHash: 0x...,
            vrfCallbackGasLimit: 500_000,
            vrfRequestConfirmations: 3
        });
    }
}
```

## Resources

- [Chainlink VRF Docs](https://docs.chain.link/vrf/v2-5/supported-networks)
- [Uniswap Permit2](https://github.com/Uniswap/permit2)
- [Euler EVC](https://github.com/euler-xyz/ethereum-vault-connector)
