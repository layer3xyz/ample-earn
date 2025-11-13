// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

import {VRFConfig} from "../interfaces/IAmpleDraw.sol";

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

/// @title AmpleEventsLib
/// @author Ample Money
/// @custom:contact security@ample.money
/// @notice Library exposing events.
library AmpleEventsLib {
    /// @notice Emitted when the `merkleRoot` is set for a given `prizeId` and `totalTwab`.
    event SetMerkleRoot(uint256 indexed prizeId, bytes32 indexed merkleRoot, uint256 indexed totalTwab);

    /// @notice Emitted when `prizeDraw` is set to `newPrizeDraw`.
    event SetPrizeDraw(address indexed newPrizeDraw);

    /// @notice Emitted when an `prizekeeper` is set to `isPrizekeeper`.
    event SetIsPrizekeeper(address indexed prizekeeper, bool indexed isPrizekeeper);

    /// @notice Emitted when a prize is claimed for a given `claimer`, `to`, and `prizeAmount`.
    event ClaimPrize(address indexed claimer, address indexed to, uint256 prizeAmount);

    /// @notice Emitted when a prize is redeemed for a given `to` and `prizeAmount`.
    event RedeemPrize(address indexed to, uint256 prizeAmount);

    /// @notice Emitted when a prize draw is fulfilled for a given `requestId`, `winningTicketId`, and `rawRandom`.
    event PrizeDrawFulfilled(uint256 indexed requestId, uint256 indexed winningTicketId, uint256 rawRandom);

    /// @notice Emitted when a prize draw is requested for a given `requestId` and `prizeId`.
    event PrizeDrawRequested(uint256 indexed requestId, uint256 indexed prizeId);

    /// @notice Emitted when a winner is drawn for a given `prizeId` and `nativePayment`.
    event DrawWinner(uint256 indexed prizeId, bool indexed nativePayment);

    /// @notice Emitted when the winning ticket ID is set for a given `prizeId` and `winningTicketId`.
    event SetWinningTicketId(uint256 indexed prizeId, uint256 indexed winningTicketId);

    /// @notice Emitted when the VRF config is updated.
    event UpdateVRFConfig(VRFConfig indexed vrfConfig);

    /// @notice Emitted when a new AmpleEarn vault is created.
    /// @param ampleEarn The address of the AmpleEarn vault.
    /// @param caller The caller of the function.
    /// @param initialOwner The initial owner of the AmpleEarn vault.
    /// @param initialTimelock The initial timelock of the AmpleEarn vault.
    /// @param asset The address of the underlying asset.
    /// @param name The name of the AmpleEarn vault.
    /// @param symbol The symbol of the AmpleEarn vault.
    /// @param salt The salt used for the AmpleEarn vault's CREATE2 address.
    event CreateAmpleEarn(
        address indexed ampleEarn,
        address indexed caller,
        address initialOwner,
        uint256 initialTimelock,
        address indexed asset,
        string name,
        string symbol,
        bytes32 salt
    );
}
