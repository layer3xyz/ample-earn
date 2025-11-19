// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import {DEFAULT_CALLBACK_GAS_LIMIT, ChainConfig, VRFConfig} from "../ChainConfig.sol";

/// @notice Berachain configuration
library BerachainConfig {
    uint256 internal constant CHAIN_ID = 80094;

    function getConfig() internal pure returns (ChainConfig memory) {
        return ChainConfig({
            // Protocol addresses: https://docs.euler.finance/developers/contract-addresses/
            evc: 0x45334608ECE7B2775136bC847EB92B5D332806A9,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            evkFactoryPerspective: 0xEE0CA74F3c60B7e1366e6d64AE2426E5177145cf,
            eulerEarnFactory: 0x9cbc3030e6d133D1AAa148D598FD82D70263495c,
            // Chainlink VRF V2.5: https://vrf.chain.link/
            vrfCoordinator: 0x0000000000000000000000000000000000000000, // TODO: Add VRF Coordinator address
            vrfConfig: VRFConfig({
                subscriptionId: 0, // TODO: Add VRF Subscription ID
                keyHash: 0x0000000000000000000000000000000000000000000000000000000000000000, // TODO: Add VRF Key Hash
                callbackGasLimit: DEFAULT_CALLBACK_GAS_LIMIT,
                requestConfirmations: 0 // TODO: Add VRF Request Confirmations
            })
        });
    }
}
