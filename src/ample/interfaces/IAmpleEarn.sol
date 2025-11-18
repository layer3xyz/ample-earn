// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

import {IERC4626} from "openzeppelin-contracts/interfaces/IERC4626.sol";
import {IEulerEarnStaticTyping} from "../../interfaces/IEulerEarn.sol";

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

struct PrizePool {
    bytes32 merkleRoot;
    uint256 totalTwab;
    uint256 winningTicketId;
    uint256 prize;
    bool claimed;
}

struct PrizePoolMerkleLeaf {
    address user;
    uint256 twab;
    uint256 ticketStart;
    uint256 ticketEnd;
}

/// @title IAmpleEarn
/// @author Ample Money
/// @custom:contact security@ample.money
/// @notice An interface for the AmpleEarn contract.
interface IAmpleEarn is IERC4626, IEulerEarnStaticTyping {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           STORAGE                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice The address of the AmpleDraw contract.
    function prizeDraw() external view returns (address);

    /// @notice Whether an account is a prizekeeper.
    function isPrizekeeper(address account) external view returns (bool);

    /// @notice The prize pool for a given prize ID.
    function prizePool(uint256 prizeId) external view returns (bytes32, uint256, uint256, uint256, bool);

    /// @notice The total prizes claimed from the prize draw.
    function claimedPrizes(address prizeDraw) external view returns (uint256);

    /// @notice The total prizes locked in the prize draw.
    function lockedPrizes(address prizeDraw) external view returns (uint256);

    /// @notice The total prizes claimed from the prize draw.
    function totalPrizesClaimed() external view returns (uint256);

    /// @notice The total prizes locked in the prize draw.
    function totalPrizesLocked() external view returns (uint256);

    /// @notice The current prize ID.
    function currentPrizeId() external view returns (uint256);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    ONLY OWNER FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Set the AmpleDraw contract address.
    function setPrizeDraw(address newPrizeDraw) external;

    /// @notice Set whether an account is a prizekeeper.
    function setIsPrizekeeper(address newPrizekeeper, bool newIsPrizekeeper) external;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                 ONLY PRIZEKEEPER FUNCTIONS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Draw a winner for a given prize ID.
    function drawWinner(uint256 prizeId, bool nativePayment) external;

    /// @notice Set the Merkle root for a given prize ID.
    function setMerkleRoot(bytes32 merkleRoot, uint256 totalTwab) external returns (uint256);

    /// @notice Set the winning ticket ID for a given prize ID.
    function setWinningTicketId(uint256 prizeId, uint256 winningTicketId) external;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    PRIZE VAULT (PUBLIC)                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Claim a prize for a given prize ID.
    function claimPrize(
        uint256 prizeId,
        address to,
        PrizePoolMerkleLeaf memory merkleLeaf,
        bytes32[] calldata merkleProof
    ) external;

    /// @notice Get the current prize amount.
    function getCurrentPrizeAmount() external view returns (uint256);
}
