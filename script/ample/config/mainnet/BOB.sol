// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import {DEFAULT_CALLBACK_GAS_LIMIT, ChainConfig, VRFConfig} from "../ChainConfig.sol";

/// @notice BOB configuration
library BOBConfig {
    uint256 internal constant CHAIN_ID = 60808;

    function getConfig() internal pure returns (ChainConfig memory) {
        return ChainConfig({
            // Protocol addresses: https://docs.euler.finance/developers/contract-addresses/: https://docs.euler.finance/developers/contract-addresses/
            evc: 0x59f0FeEc4fA474Ad4ffC357cC8d8595B68abE47d,
            permit2: 0xCbe9Be2C87b24b063A21369b6AB0Aa9f149c598F,
            evkFactoryPerspective: 0x05B98f64A31A33666cC9D2B32046a6Ca42699823,
            eulerEarnFactory: 0x8F01c6640A1c0a6085C79843F861fF0F89b9fED6,
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
