// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {VRFV2PlusClient} from "chainlink-brownie-contracts/v0.8/dev/vrf/libraries/VRFV2PlusClient.sol";
import {VRFConsumerBaseV2Plus} from "chainlink-brownie-contracts/v0.8/dev/vrf/VRFConsumerBaseV2Plus.sol";

import {IAmpleDraw, VRFConfig, NUM_WORDS} from "./interfaces/IAmpleDraw.sol";
import {IAmpleEarn} from "./interfaces/IAmpleEarn.sol";
import {AmpleErrorsLib} from "./libraries/AmpleErrorsLib.sol";
import {AmpleEventsLib} from "./libraries/AmpleEventsLib.sol";

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

/// @title AmpleDraw
/// @author Ample Money
/// @custom:contact security@ample.money
/// @notice A contract for drawing prizes from a vault using a VRF
contract AmpleDraw is IAmpleDraw, VRFConsumerBaseV2Plus {
    using SafeERC20 for IERC20;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         IMMUTABLES                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @inheritdoc IAmpleDraw
    IAmpleEarn public immutable AMPLE_EARN;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           STORAGE                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @inheritdoc IAmpleDraw
    VRFConfig public vrfConfig;

    /// @inheritdoc IAmpleDraw
    mapping(uint256 => uint256) public requests;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTRUCTOR                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Initializes the contract.
    /// @param vrfCoordinator The address of the VRF coordinator
    /// @param _vrfConfig The VRF configuration
    constructor(IAmpleEarn ampleEarn, address vrfCoordinator, VRFConfig memory _vrfConfig)
        VRFConsumerBaseV2Plus(vrfCoordinator)
    {
        if (vrfCoordinator == address(0)) revert AmpleErrorsLib.ZeroAddress();
        vrfConfig = _vrfConfig;
        AMPLE_EARN = ampleEarn;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          MODIFIERS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Reverts if the caller is not the AmpleEarn contract.
    modifier onlyAmpleEarn() {
        if (msg.sender != address(AMPLE_EARN)) revert AmpleErrorsLib.NotAmpleEarn();

        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                 ONLY PRIZE VAULT FUNCTIONS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @inheritdoc IAmpleDraw
    function requestDraw(uint256 prizeId, bool nativePayment) external onlyAmpleEarn returns (uint256 requestId) {
        (,, uint256 winningTicketId,,) = AMPLE_EARN.prizePool(prizeId);
        if (winningTicketId != 0) revert AmpleErrorsLib.WinningTicketIdAlreadySet();

        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: vrfConfig.keyHash,
                subId: vrfConfig.subscriptionId,
                requestConfirmations: vrfConfig.requestConfirmations,
                callbackGasLimit: vrfConfig.callbackGasLimit,
                numWords: NUM_WORDS, // TODO: Consider making this dynamic
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: nativePayment}))
            })
        );
        requests[requestId] = prizeId;

        emit AmpleEventsLib.PrizeDrawRequested(requestId, prizeId);
    }

    /// @inheritdoc IAmpleDraw
    function safeTransferPrize(address to, uint256 prize) external onlyAmpleEarn {
        IERC20(address(AMPLE_EARN)).safeTransfer(to, prize);

        emit AmpleEventsLib.RedeemPrize(to, prize);
    }

    /// @inheritdoc IAmpleDraw
    function updateVRFConfig(VRFConfig memory _vrfConfig) external onlyAmpleEarn {
        vrfConfig = _vrfConfig;

        emit AmpleEventsLib.UpdateVRFConfig(_vrfConfig);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     CHAINLINK CALLBACK                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @notice Chainlink callback
     * @param requestId The request ID
     * @param randomWords The random words
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 prizeId = requests[requestId];
        delete requests[requestId];

        // We revert here because our backend should have some logic to ensure the twab
        // is not 0 in order to perform the draw.
        (, uint256 space,,,) = AMPLE_EARN.prizePool(prizeId);
        if (space == 0) revert AmpleErrorsLib.EmptySpace();

        // Best practice from docs: modulo to fit a range (1..space)
        uint256 raw = randomWords[0];

        // Range is 1..space
        uint256 winningTicketId = (raw % space) + 1;

        emit AmpleEventsLib.PrizeDrawFulfilled(prizeId, winningTicketId, raw);

        AMPLE_EARN.setWinningTicketId(prizeId, winningTicketId);
    }
}
