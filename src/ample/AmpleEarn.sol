// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

import {MerkleProof} from "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";

import {EulerEarn, EventsLib} from "../EulerEarn.sol";

import {IAmpleEarn, PrizePool, PrizePoolMerkleLeaf} from "./interfaces/IAmpleEarn.sol";
import {AmpleErrorsLib} from "./libraries/AmpleErrorsLib.sol";
import {AmpleEventsLib} from "./libraries/AmpleEventsLib.sol";
import {AmpleDraw, IAmpleDraw, VRFConfig} from "./AmpleDraw.sol";

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

/// @title AmpleEarn
/// @author Ample Money. Forked with gratitude from Euler Labs.
/// @custom:contact security@euler.xyz
/// @custom:contact security@ample.money
/// @notice A protocol to pool your yield to win massive prizes.
contract AmpleEarn is EulerEarn, IAmpleEarn {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           STORAGE                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @inheritdoc IAmpleEarn
    address public prizeDraw;

    /// @inheritdoc IAmpleEarn
    mapping(address account => bool isPrizekeeper) public isPrizekeeper;

    /// @inheritdoc IAmpleEarn
    mapping(uint256 prizeId => PrizePool prizePool) public prizePool;

    /// @inheritdoc IAmpleEarn
    mapping(address prizeDraw => uint256 totalClaimed) public claimedPrizes;

    /// @inheritdoc IAmpleEarn
    mapping(address prizeDraw => uint256 totalLocked) public lockedPrizes;

    /// @inheritdoc IAmpleEarn
    uint256 public totalPrizesClaimed;

    /// @inheritdoc IAmpleEarn
    uint256 public totalPrizesLocked;

    /// @inheritdoc IAmpleEarn
    uint256 public currentPrizeId;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTRUCTOR                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Initializes the contract.
    /// @param owner The owner of the contract.
    /// @param evc The EVC address.
    /// @param permit2 The address of the Permit2 contract.
    /// @param initialTimelock The initial timelock.
    /// @param _asset The address of the underlying asset.
    /// @param __name The name of the Earn vault.
    /// @param __symbol The symbol of the Earn vault.
    /// @dev We pass "" as name and symbol to the ERC20 because these are overriden in this contract.
    /// This means that the contract deviates slightly from the ERC2612 standard.
    constructor(
        address owner,
        address evc,
        address permit2,
        uint256 initialTimelock,
        address _asset,
        string memory __name,
        string memory __symbol,
        address vrfCoordinator,
        VRFConfig memory vrfConfig
    ) EulerEarn(owner, evc, permit2, initialTimelock, _asset, __name, __symbol) {
        prizeDraw = address(new AmpleDraw(this, vrfCoordinator, vrfConfig));
        emit AmpleEventsLib.SetPrizeDraw(prizeDraw);

        feeRecipient = prizeDraw;
        emit EventsLib.SetFeeRecipient(prizeDraw);

        fee = 1e18; // 100% fee
        emit EventsLib.SetFee(_msgSender(), fee);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          MODIFIERS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Reverts if the caller doesn't have the prizekeeper role.
    modifier onlyPrizekeeperRole() {
        address msgSender = _msgSenderOnlyEVCAccountOwner();
        if (!isPrizekeeper[msgSender] && msgSender != owner()) revert AmpleErrorsLib.NotPrizekeeperRole();

        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    ONLY OWNER FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // TODO: Consider adding a timelock to these functions

    /// @inheritdoc IAmpleEarn
    function setPrizeDraw(address newPrizeDraw) external onlyOwner {
        // TODO: Rotate pool on every new draw
        if (newPrizeDraw == prizeDraw) revert AmpleErrorsLib.AlreadySet();

        prizeDraw = newPrizeDraw;

        emit AmpleEventsLib.SetPrizeDraw(newPrizeDraw);
    }

    /// @inheritdoc IAmpleEarn
    function setIsPrizekeeper(address newPrizekeeper, bool newIsPrizekeeper) external onlyOwner {
        if (isPrizekeeper[newPrizekeeper] == newIsPrizekeeper) revert AmpleErrorsLib.AlreadySet();

        isPrizekeeper[newPrizekeeper] = newIsPrizekeeper;

        emit AmpleEventsLib.SetIsPrizekeeper(newPrizekeeper, newIsPrizekeeper);
    }

    // TODO: Add sweep prize & emergency rescue

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                 ONLY PRIZEKEEPER FUNCTIONS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @inheritdoc IAmpleEarn
    function drawWinner(uint256 prizeId, bool nativePayment) external nonReentrant onlyPrizekeeperRole {
        if (prizeId >= currentPrizeId) revert AmpleErrorsLib.PrizeIdInvalid();
        if (prizePool[prizeId].merkleRoot == bytes32(0)) revert AmpleErrorsLib.MerkleRootNotSet();
        if (prizePool[prizeId].totalTwab == 0) revert AmpleErrorsLib.ZeroTwab();
        if (prizePool[prizeId].prize == 0) revert AmpleErrorsLib.ZeroPrize();
        if (prizePool[prizeId].winningTicketId != 0) revert AmpleErrorsLib.WinningTicketIdAlreadySet();

        emit AmpleEventsLib.DrawWinner(prizeId, nativePayment);

        IAmpleDraw(prizeDraw).requestDraw(prizeId, nativePayment);
    }

    /// @inheritdoc IAmpleEarn
    function setMerkleRoot(bytes32 merkleRoot, uint256 totalTwab)
        external
        nonReentrant
        onlyPrizekeeperRole
        returns (uint256 prizeId)
    {
        if (merkleRoot == bytes32(0)) revert AmpleErrorsLib.MerkleRootEmpty();
        if (prizePool[currentPrizeId].merkleRoot != bytes32(0)) revert AmpleErrorsLib.AlreadySet();
        if (totalTwab == 0) revert AmpleErrorsLib.ZeroTwab();

        _accrueInterest();

        if (_calculateAccruedInterestInPrizeDraw() == 0) revert AmpleErrorsLib.ZeroPrize();

        // uint256 prize = prizePool[currentPrizeId].prize;
        // TODO: Edge case, check lostAssets
        // require(prize == accumulatedFees, "INSUFFICIENT_FEES");

        prizePool[currentPrizeId].merkleRoot = merkleRoot;
        prizePool[currentPrizeId].totalTwab = totalTwab;

        uint256 accruedInterestInPrizeDraw = _calculateAccruedInterestInPrizeDraw();
        prizePool[currentPrizeId].prize = accruedInterestInPrizeDraw;

        // Update global state
        totalPrizesLocked += accruedInterestInPrizeDraw;

        // Update prize draw state
        lockedPrizes[prizeDraw] += accruedInterestInPrizeDraw;

        currentPrizeId++;

        emit AmpleEventsLib.SetMerkleRoot(currentPrizeId - 1, merkleRoot, totalTwab);

        return currentPrizeId - 1;
    }

    /// @inheritdoc IAmpleEarn
    function setWinningTicketId(uint256 prizeId, uint256 winningTicketId) external {
        if (_msgSenderOnlyEVCAccountOwner() != address(prizeDraw)) revert AmpleErrorsLib.NotPrizeDrawRole();
        if (prizePool[prizeId].merkleRoot == bytes32(0)) revert AmpleErrorsLib.MerkleRootNotSet();
        if (prizePool[prizeId].winningTicketId != 0) revert AmpleErrorsLib.WinningTicketIdAlreadySet();
        prizePool[prizeId].winningTicketId = winningTicketId;

        emit AmpleEventsLib.SetWinningTicketId(prizeId, winningTicketId);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    PRIZE VAULT (PUBLIC)                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @inheritdoc IAmpleEarn
    function claimPrize(
        uint256 prizeId,
        address to,
        PrizePoolMerkleLeaf memory merkleLeaf,
        bytes32[] calldata merkleProof
    ) external nonReentrant {
        if (to == address(0)) revert AmpleErrorsLib.ZeroAddress();
        if (prizePool[prizeId].merkleRoot == bytes32(0)) revert AmpleErrorsLib.MerkleRootNotSet();

        address msgSender = _msgSenderOnlyEVCAccountOwner();

        if (
            msgSender != merkleLeaf.user || merkleLeaf.ticketEnd <= prizePool[prizeId].winningTicketId
                || merkleLeaf.ticketStart > prizePool[prizeId].winningTicketId + prizePool[prizeId].totalTwab
        ) revert AmpleErrorsLib.NotPrizeWinner();

        if (prizePool[prizeId].claimed) revert AmpleErrorsLib.PrizeClaimed();

        bytes32 leaf =
            keccak256(abi.encode(merkleLeaf.user, merkleLeaf.twab, merkleLeaf.ticketStart, merkleLeaf.ticketEnd));
        if (!MerkleProof.verify(merkleProof, prizePool[prizeId].merkleRoot, leaf)) {
            revert AmpleErrorsLib.MerkleProofInvalid();
        }

        prizePool[prizeId].claimed = true;

        // Update prize draw state
        claimedPrizes[prizeDraw] += prizePool[prizeId].prize;
        lockedPrizes[prizeDraw] -= prizePool[prizeId].prize;

        // Update global state
        totalPrizesClaimed += prizePool[prizeId].prize;
        totalPrizesLocked -= prizePool[prizeId].prize;

        emit AmpleEventsLib.ClaimPrize(msgSender, to, prizePool[prizeId].prize);

        // Withdraw prize from Euler vault
        IAmpleDraw(prizeDraw).safeTransferPrize(to, prizePool[prizeId].prize);
    }

    /// @inheritdoc IAmpleEarn
    function getCurrentPrizeAmount() external view returns (uint256 prizeAmount) {
        prizeAmount = _calculateAccruedInterestInPrizeDraw();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          INTERNAL                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _calculateAccruedInterestInPrizeDraw() internal view returns (uint256) {
        return balanceOf(prizeDraw) - lockedPrizes[prizeDraw] - claimedPrizes[prizeDraw];
    }
}
