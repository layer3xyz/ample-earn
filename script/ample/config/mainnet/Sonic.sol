// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import {DEFAULT_CALLBACK_GAS_LIMIT, ChainConfig, VRFConfig} from "../ChainConfig.sol";

/// @notice Sonic configuration
library SonicConfig {
    uint256 internal constant CHAIN_ID = 146;

    function getConfig() internal pure returns (ChainConfig memory) {
        return ChainConfig({
            // Protocol addresses: https://docs.euler.finance/developers/contract-addresses/
            evc: 0x4860C903f6Ad709c3eDA46D3D502943f184D4315,
            permit2: 0xB952578f3520EE8Ea45b7914994dcf4702cEe578,
            evkFactoryPerspective: 0x69D2403d9a0715CDc89AcB015Ec2AfB200C4f6BD,
            eulerEarnFactory: 0x3397ec7d28cF645A017869Fe4B41c75f5B0b75a8,
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
