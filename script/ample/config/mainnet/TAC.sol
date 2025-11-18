// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import {DEFAULT_CALLBACK_GAS_LIMIT, ChainConfig, VRFConfig} from "../ChainConfig.sol";

/// @notice TAC configuration
library TACConfig {
    uint256 internal constant CHAIN_ID = 239;

    function getConfig() internal pure returns (ChainConfig memory) {
        return ChainConfig({
            // Protocol addresses: https://docs.euler.finance/developers/contract-addresses/
            evc: 0x01F594c66A5561b90Bc782dD0297f294cD668b64,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            evkFactoryPerspective: 0xC194A7A86592C712BC155979A233B3d6F00e604a,
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
