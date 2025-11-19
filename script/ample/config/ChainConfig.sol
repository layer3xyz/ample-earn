// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import {VRFConfig} from "../../../src/ample/interfaces/IAmpleDraw.sol";

/*
                                   /$$
                                  | $$
  /$$$$$$  /$$$$$$/$$$$   /$$$$$$ | $$  /$$$$$$
 |____  $$| $$_  $$_  $$ /$$__  $$| $$ /$$__  $$
  /$$$$$$$| $$ \ $$ \ $$| $$  \ $$| $$| $$$$$$$$
 /$$__  $$| $$ | $$ | $$| $$  | $$| $$| $$_____/
|  $$$$$$$| $$ | $$ | $$| $$$$$$$/| $$|  $$$$$$$
 \_______/|__/ |__/ |__/| $$____/ |__/ \_______/
                        | $$
                        | $$
                        |__/
*/

uint32 constant DEFAULT_CALLBACK_GAS_LIMIT = 130_000; // TODO: Verify this

/// @notice Chain-specific configuration for deployments
/// @dev Protocol addresses are available at: https://docs.euler.finance/developers/contract-addresses/
/// @dev Chainlink VRF addresses are available at: https://vrf.chain.link/<CHAIN_NAME>
struct ChainConfig {
    // Protocol addresses: https://docs.euler.finance/developers/contract-addresses/
    address evc;
    address permit2;
    address evkFactoryPerspective;
    // Chainlink VRF: https://vrf.chain.link/
    address vrfCoordinator;
    VRFConfig vrfConfig;
}
