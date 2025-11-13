// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

import {IAmpleEarn} from "./IAmpleEarn.sol";

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

/// @dev The number of words to request from the VRF
uint32 constant NUM_WORDS = 1;

/// @notice The configuration for the VRF
/// @param subscriptionId Chainlink subscription ID (https://vrf.chain.link)
/// @param keyHash Gas lane to use, which specifies the maximum gas price to bump to.
///        For a list of available gas lanes on each network, see: https://docs.chain.link/vrf/v2-5/supported-networks
/// @param callbackGasLimit Callback gas limit for the VRF, should be adjusted based on network.
/// @param requestConfirmations Can set this higher, but default is 3.
struct VRFConfig {
    uint256 subscriptionId;
    bytes32 keyHash;
    uint32 callbackGasLimit;
    uint16 requestConfirmations;
}

/// @title IAmpleDraw
/// @author Ample Money
/// @custom:contact security@ample.money
/// @notice An interface for the AmpleDraw contract
interface IAmpleDraw {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         IMMUTABLES                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice The prize vault
    function AMPLE_EARN() external view returns (IAmpleEarn);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           STORAGE                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice The VRF configuration
    function vrfConfig() external view returns (uint256, bytes32, uint32, uint16);

    /// @notice The requests mapping (requestId => prizeId)
    function requests(uint256 requestId) external view returns (uint256);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                 ONLY PRIZE VAULT FUNCTIONS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Redeem a prize from the prize vault
    function redeemPrize(address to, uint256 prize) external;

    /// @notice Request a draw for a given draw ID
    function requestDraw(uint256 prizeId, bool nativePayment) external returns (uint256 requestId);

    /// @notice Update the VRF configuration
    function updateVRFConfig(VRFConfig memory _vrfConfig) external;
}
