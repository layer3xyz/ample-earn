// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import {DEFAULT_CALLBACK_GAS_LIMIT, ChainConfig, VRFConfig} from "../ChainConfig.sol";

/// @notice Ethereum configuration
library EthereumConfig {
    uint256 internal constant CHAIN_ID = 1;

    function getConfig() internal pure returns (ChainConfig memory) {
        return ChainConfig({
            // Protocol addresses: https://docs.euler.finance/developers/contract-addresses/
            evc: 0x0C9a3dd6b8F28529d72d7f9cE918D493519EE383,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            evkFactoryPerspective: 0xB30f23bc5F93F097B3A699f71B0b1718Fc82e182,
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
