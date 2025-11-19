// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import {DEFAULT_CALLBACK_GAS_LIMIT, ChainConfig, VRFConfig} from "../ChainConfig.sol";

/// @notice BSC configuration
library BSCConfig {
    uint256 internal constant CHAIN_ID = 56;

    function getConfig() internal pure returns (ChainConfig memory) {
        return ChainConfig({
            // Protocol addresses: https://docs.euler.finance/developers/contract-addresses/
            evc: 0xb2E5a73CeE08593d1a076a2AE7A6e02925a640ea,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            evkFactoryPerspective: 0x9d928D359646dC4249A8d57259d87673F118Ec85,
            eulerEarnFactory: 0xc456d04E3F43597CC7E5a2AF284fF4C4AdDA0cb1,
            // Chainlink VRF V2.5: https://vrf.chain.link/bsc
            vrfCoordinator: 0xd691f04bc0C9a24Edb78af9E005Cf85768F694C9,
            vrfConfig: VRFConfig({
                subscriptionId: 0, // TODO: Add VRF Subscription ID
                keyHash: 0x0000000000000000000000000000000000000000000000000000000000000000, // TODO: Add VRF Key Hash
                callbackGasLimit: DEFAULT_CALLBACK_GAS_LIMIT,
                requestConfirmations: 0 // TODO: Add VRF Request Confirmations
            })
        });
    }
}
