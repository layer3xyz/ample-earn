/// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

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

/// @title AmpleErrorsLib
/// @author Ample Money
/// @custom:contact security@ample.money
/// @notice Library exposing error messages.
library AmpleErrorsLib {
    /// @notice Thrown when the address passed is the zero address.
    error ZeroAddress();

    /// @notice Thrown when the total TWAB is zero.
    error ZeroTwab();

    /// @notice Thrown when the prize is zero.
    error ZeroPrize();

    /// @notice Thrown when the caller doesn't have the prize draw role.
    error NotPrizeDrawRole();

    /// @notice Thrown when the caller doesn't have the prize keeper role.
    error NotPrizekeeperRole();

    /// @notice Thrown when the caller is not the AmpleEarn contract.
    error NotAmpleEarn();

    /// @notice Thrown when the caller is not a prize winner.
    error NotPrizeWinner();

    /// @notice Thrown when the value is already set.
    error AlreadySet();

    /// @notice Thrown when the space is empty (e.g. no deposits yet).
    error EmptySpace();

    /// @notice Thrown when the Merkle proof is invalid.
    error MerkleProofInvalid();

    /// @notice Thrown when the Merkle root is empty.
    error MerkleRootEmpty();

    /// @notice Thrown when the Merkle root is not set.
    error MerkleRootNotSet();

    /// @notice Thrown when the prize has been claimed.
    error PrizeClaimed();

    /// @notice Thrown when the prize draw is already set.
    error PrizeDrawAlreadySet();

    /// @notice Thrown when the prize ID is invalid.
    error PrizeIdInvalid();

    /// @notice Thrown when the winning ticket ID is already set.
    error WinningTicketIdAlreadySet();
}
