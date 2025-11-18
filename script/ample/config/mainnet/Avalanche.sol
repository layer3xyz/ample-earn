// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import {DEFAULT_CALLBACK_GAS_LIMIT, ChainConfig, VRFConfig} from "../ChainConfig.sol";

/// @notice Avalanche configuration
library AvalancheConfig {
    uint256 internal constant CHAIN_ID = 43114;

    function getConfig() internal pure returns (ChainConfig memory) {
        return ChainConfig({
            // Protocol addresses: https://docs.euler.finance/developers/contract-addresses/
            evc: 0xddcbe30A761Edd2e19bba930A977475265F36Fa1,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            evkFactoryPerspective: 0x4247432b4f9c32e99ecC2Ff7bAdd98783EecFA6F,
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
