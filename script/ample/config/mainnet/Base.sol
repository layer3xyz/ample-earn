// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import {DEFAULT_CALLBACK_GAS_LIMIT, ChainConfig, VRFConfig} from "../ChainConfig.sol";

/// @notice Base configuration
library BaseConfig {
    uint256 internal constant CHAIN_ID = 8453;

    function getConfig() internal pure returns (ChainConfig memory) {
        return ChainConfig({
            // Protocol addresses: https://docs.euler.finance/developers/contract-addresses/
            evc: 0x5301c7dD20bD945D2013b48ed0DEE3A284ca8989,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            evkFactoryPerspective: 0xFEA8e8a4d7ab8C517c3790E49E92ED7E1166F651,
            eulerEarnFactory: 0x75F49a2621b6DeC6a5baB22ce961bF3e676EFAE6,
            // Chainlink VRF V2.5: https://vrf.chain.link/base
            vrfCoordinator: 0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634,
            vrfConfig: VRFConfig({
                subscriptionId: 46339755996284568570734542574021276111078872986542721088003120035887577957173, // TODO: Add Production Subscription ID
                keyHash: 0xdc2f87677b01473c763cb0aee938ed3341512f6057324a584e5944e786144d70, // 30 Gwei
                callbackGasLimit: DEFAULT_CALLBACK_GAS_LIMIT,
                requestConfirmations: 3
            })
        });
    }
}
