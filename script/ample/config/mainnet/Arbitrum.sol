// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import {DEFAULT_CALLBACK_GAS_LIMIT, ChainConfig, VRFConfig} from "../ChainConfig.sol";

/// @notice Arbitrum One configuration
library ArbitrumConfig {
    uint256 internal constant CHAIN_ID = 42161;

    function getConfig() internal pure returns (ChainConfig memory) {
        return ChainConfig({
            // Protocol addresses: https://docs.euler.finance/developers/contract-addresses/
            evc: 0x6302ef0F34100CDDFb5489fbcB6eE1AA95CD1066,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            evkFactoryPerspective: 0x03a931446F5A7e7ec1D850D8eaF95Ab68Ad9089C,
            eulerEarnFactory: 0xB9B5d62B9fE9E1B505466e75817aB178A1D2ec9d,
            // Chainlink VRF V2.5: https://vrf.chain.link/
            vrfCoordinator: 0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634,
            vrfConfig: VRFConfig({
                subscriptionId: 0, // TODO: Add VRF Subscription ID
                keyHash: 0xdc2f87677b01473c763cb0aee938ed3341512f6057324a584e5944e786144d70, // 30 Gwei
                callbackGasLimit: DEFAULT_CALLBACK_GAS_LIMIT,
                requestConfirmations: 0 // TODO: Add VRF Request Confirmations
            })
        });
    }
}
