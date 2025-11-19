// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.26;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "openzeppelin-contracts/interfaces/IERC4626.sol";
import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

import {IAmpleEarn, PrizePoolMerkleLeaf} from "../../../src/ample/interfaces/IAmpleEarn.sol";
import {IAmpleDraw, VRFConfig} from "../../../src/ample/interfaces/IAmpleDraw.sol";
import {IAmpleEarnFactory} from "../../../src/ample/interfaces/IAmpleEarnFactory.sol";
import {AmpleEarn} from "../../../src/ample/AmpleEarn.sol";
import {AmpleEarnFactory} from "../../../src/ample/AmpleEarnFactory.sol";
import {IOwnable} from "../../../src/interfaces/IEulerEarn.sol";
import {MerkleHelper} from "../helpers/MerkleHelper.sol";
import {VRFCoordinatorV2_5Mock} from "../mocks/chainlink/VRFCoordinatorV2_5Mock.sol";
import {IPerspective} from "../../../src/interfaces/IPerspective.sol";

uint256 constant TIMELOCK = 1 weeks;

/// @title AmpleEarnForkTest
/// @notice Fork tests for AmpleEarn on Base mainnet using real Euler vaults
contract AmpleEarnForkTest is Test {
    // Base mainnet addresses - Euler V2 Core
    IERC20 constant USDC = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);
    address constant EULER_VAULT_USDC = 0x0A1a3b5f2041F33522C4efc754a7D096f880eE16;
    address constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address constant BASE_EVC_ADDRESS = 0x5301c7dD20bD945D2013b48ed0DEE3A284ca8989;

    // Test users
    address internal OWNER;
    address internal PRIZEKEEPER;
    address internal DEPOSITOR;
    address internal SUPPLIER;
    address internal RECEIVER;
    address internal ONBEHALF;
    address internal CURATOR;
    address internal ALLOCATOR;

    IAmpleEarnFactory ampleEarnFactory;
    IAmpleEarn vault;
    IERC4626 eulerVault;
    VRFCoordinatorV2_5Mock vrfCoordinator;
    uint256 vrfSubscriptionId;
    IPerspective perspective;

    modifier whenUserHasBalance(address token, address user, uint256 amount) {
        deal(token, user, amount);
        _;
    }

    modifier whenUserHasDeposit(address user, uint256 amount) {
        vm.startPrank(user);
        USDC.approve(address(vault), amount);
        vault.deposit(amount, user);
        vm.stopPrank();
        _;
    }

    /// @dev Triggers interest accrual by making a tiny deposit
    /// This is needed because interest doesn't accrue automatically - it needs to be triggered
    function _accrueInterest() internal {
        // Make a tiny deposit to trigger _accrueInterest() in the vault
        address accruer = makeAddr("Accruer");
        deal(address(USDC), accruer, 1e6); // 1 USDC
        vm.startPrank(accruer);
        USDC.approve(address(vault), 1e6);
        vault.deposit(1e6, accruer);
        vm.stopPrank();
    }

    function setUpVRF() public returns (uint256 subscriptionId) {
        uint96 baseFee = 1e17;
        uint96 gasPrice = 1e9;
        int256 weiPerUnitLink = 4e15;

        vrfCoordinator = new VRFCoordinatorV2_5Mock(baseFee, gasPrice, weiPerUnitLink);
        console.log("Deployed Chainlink VRFCoordinator: %s", address(vrfCoordinator));
        vm.label({account: address(vrfCoordinator), newLabel: "VRFCoordinator"});

        subscriptionId = vrfCoordinator.createSubscription();
        // Fund with native tokens (ETH) following Chainlink test patterns
        vrfCoordinator.fundSubscriptionWithNative{value: 10 ether}(subscriptionId);
    }

    function setUp() public virtual {
        // Fork Base mainnet at a recent block
        vm.createSelectFork(vm.envString("BASE_RPC_URL"), 30_036_405);

        // Create test users
        OWNER = makeAddr("Owner");
        PRIZEKEEPER = makeAddr("Prizekeeper");
        DEPOSITOR = makeAddr("Depositor");
        SUPPLIER = makeAddr("Supplier");
        RECEIVER = makeAddr("Receiver");
        ONBEHALF = makeAddr("OnBehalf");
        CURATOR = makeAddr("Curator");
        ALLOCATOR = makeAddr("Allocator");

        vm.deal(OWNER, 100 ether);
        vm.deal(PRIZEKEEPER, 100 ether);
        vm.deal(DEPOSITOR, 100 ether);
        vm.deal(SUPPLIER, 100 ether);
        vm.deal(RECEIVER, 100 ether);
        vm.deal(ONBEHALF, 100 ether);

        // Label test users
        vm.label({account: OWNER, newLabel: "Owner"});
        vm.label({account: PRIZEKEEPER, newLabel: "Prizekeeper"});
        vm.label({account: DEPOSITOR, newLabel: "Depositor"});
        vm.label({account: SUPPLIER, newLabel: "Supplier"});
        vm.label({account: RECEIVER, newLabel: "Receiver"});
        vm.label({account: ONBEHALF, newLabel: "OnBehalf"});
        vm.label({account: CURATOR, newLabel: "Curator"});
        vm.label({account: ALLOCATOR, newLabel: "Allocator"});

        // Label Base mainnet contracts
        vm.label({account: address(USDC), newLabel: "USDC"});
        vm.label({account: EULER_VAULT_USDC, newLabel: "EulerVault"});
        vm.label({account: PERMIT2_ADDRESS, newLabel: "Permit2"});
        vm.label({account: BASE_EVC_ADDRESS, newLabel: "EVC"});

        // Use real Euler vault on Base
        eulerVault = IERC4626(EULER_VAULT_USDC);

        // Setup VRF
        vrfSubscriptionId = setUpVRF();

        perspective = IPerspective(0xFEA8e8a4d7ab8C517c3790E49E92ED7E1166F651); // Perspective on Base mainnet

        vm.startPrank(OWNER);

        // Deploy factory with Base mainnet EVC/Permit2 and mock perspective
        ampleEarnFactory = new AmpleEarnFactory(OWNER, BASE_EVC_ADDRESS, PERMIT2_ADDRESS, address(perspective));

        // Create vault through factory
        vault = ampleEarnFactory.createAmpleEarn(
            OWNER,
            TIMELOCK,
            address(USDC),
            "Ample Earn USDC",
            "aeUSDC",
            bytes32(uint256(1)),
            address(vrfCoordinator),
            VRFConfig({
                subscriptionId: vrfSubscriptionId,
                keyHash: 0x0000000000000000000000000000000000000000000000000000000000000000,
                callbackGasLimit: 1000000,
                requestConfirmations: 3
            })
        );

        // Set roles
        vault.setIsPrizekeeper(PRIZEKEEPER, true);
        vault.setCurator(CURATOR);
        vault.setIsAllocator(ALLOCATOR, true);

        vm.stopPrank();

        console.log("Deployed AmpleEarn: %s", address(vault));
        console.log("PrizeDraw: %s", address(vault.prizeDraw()));

        // Set up Euler vault as a strategy with max cap
        vm.prank(CURATOR);
        vault.submitCap(eulerVault, type(uint136).max);

        // Wait for timelock and accept cap
        vm.warp(block.timestamp + TIMELOCK);
        vault.acceptCap(eulerVault);

        // Add Euler vault to supply queue
        IERC4626[] memory supplyQueue = new IERC4626[](1);
        supplyQueue[0] = eulerVault;
        vm.prank(ALLOCATOR);
        vault.setSupplyQueue(supplyQueue);

        // Add consumer to VRF subscription
        vrfCoordinator.addConsumer(vrfSubscriptionId, address(vault.prizeDraw()));
        console.log("Added consumer to VRF subscription: %s", address(vault.prizeDraw()));

        // Approve vault for all test users
        vm.prank(DEPOSITOR);
        USDC.approve(address(vault), type(uint256).max);

        vm.prank(SUPPLIER);
        USDC.approve(address(vault), type(uint256).max);

        vm.prank(RECEIVER);
        USDC.approve(address(vault), type(uint256).max);

        vm.prank(ONBEHALF);
        USDC.approve(address(vault), type(uint256).max);
    }

    function testFork_Deployment() public view {
        assertEq(vault.asset(), address(USDC), "asset should be USDC");
        assertEq(vault.name(), "Ample Earn USDC", "name should be correct");
        assertEq(vault.symbol(), "aeUSDC", "symbol should be correct");
        assertEq(IOwnable(address(vault)).owner(), OWNER, "owner should be deployer");
        assertTrue(vault.isPrizekeeper(PRIZEKEEPER), "prizekeeper should be set");
        assertEq(vault.feeRecipient(), vault.prizeDraw(), "feeRecipient should be prizeDraw");
        assertEq(vault.fee(), 1e18, "fee should be 100%");
    }

    function testFork_DepositAndAccrueYield()
        public
        whenUserHasBalance(address(USDC), DEPOSITOR, 100e6)
        whenUserHasDeposit(DEPOSITOR, 100e6)
    {
        uint256 sharesBefore = vault.balanceOf(DEPOSITOR);
        uint256 currentPrizeBefore = vault.getCurrentPrizeAmount();
        console.log("sharesBefore", sharesBefore);
        console.log("currentPrizeBefore", currentPrizeBefore);
        assertGt(sharesBefore, 0, "depositor should have shares");

        // Accrue yield by forwarding time - real Euler vault should accrue interest from borrowers
        skip(7 days);
        vm.roll(block.number + 50400); // ~7 days of blocks on Base (12 second blocks)

        // Trigger interest accrual
        _accrueInterest();

        // Check that prize has accrued
        uint256 currentPrizeAfter = vault.getCurrentPrizeAmount();
        console.log("currentPrizeAfter", currentPrizeAfter);
        assertGt(currentPrizeAfter, currentPrizeBefore, "prize should have accrued");

        // Check that prize draw has accrued fees (100% of yield)
        uint256 prizeDrawBalance = vault.balanceOf(vault.prizeDraw());
        console.log("prizeDrawBalance", prizeDrawBalance);
        assertGt(prizeDrawBalance, 0, "prizeDraw should have accrued fees");
    }

    function testFork_SetMerkleRootAndDrawWinner()
        public
        whenUserHasBalance(address(USDC), DEPOSITOR, 100e6)
        whenUserHasDeposit(DEPOSITOR, 100e6)
    {
        skip(7 days);
        vm.roll(block.number + 50400); // ~7 days of blocks
        _accrueInterest();

        // Create user TWAB data for merkle tree
        PrizePoolMerkleLeaf[] memory leaves = new PrizePoolMerkleLeaf[](4);
        leaves[0] = PrizePoolMerkleLeaf({user: DEPOSITOR, twab: 100e6, ticketStart: 0, ticketEnd: 99e6});
        leaves[1] = PrizePoolMerkleLeaf({user: SUPPLIER, twab: 50e6, ticketStart: 100e6, ticketEnd: 149e6});
        leaves[2] = PrizePoolMerkleLeaf({user: RECEIVER, twab: 75e6, ticketStart: 150e6, ticketEnd: 224e6});
        leaves[3] = PrizePoolMerkleLeaf({user: ONBEHALF, twab: 25e6, ticketStart: 225e6, ticketEnd: 249e6});

        // Generate merkle root and total TWAB
        bytes32 merkleRoot = MerkleHelper.generateMerkleRoot(leaves);
        uint256 totalTwab = 250e6; // 100 + 50 + 75 + 25

        console.log("merkleRoot:");
        console.logBytes32(merkleRoot);

        uint256 currentPrizeBefore = vault.getCurrentPrizeAmount();
        console.log("currentPrizeBefore", currentPrizeBefore);
        assertGt(currentPrizeBefore, 0, "prize should have accrued");

        vm.prank(PRIZEKEEPER);
        uint256 prizeId = vault.setMerkleRoot(merkleRoot, totalTwab);

        assertEq(prizeId, 0, "first prize ID should be 0");

        (bytes32 storedRoot, uint256 storedTwab, uint256 winningTicketId, uint256 prize, bool claimed) =
            vault.prizePool(prizeId);
        assertEq(storedRoot, merkleRoot, "merkleRoot should be stored");
        assertEq(storedTwab, totalTwab, "totalTwab should be stored");
        assertEq(winningTicketId, 0, "winningTicketId should be 0 before draw");
        assertGt(prize, 0, "prize should be greater than 0");
        assertFalse(claimed, "claimed should be false");

        uint256 currentPrizeAfter = vault.getCurrentPrizeAmount();
        console.log("currentPrizeAfter", currentPrizeAfter);
        assertEq(currentPrizeAfter, 0, "currentPrize should be 0 after merkle root set");

        vm.prank(PRIZEKEEPER);
        vault.drawWinner(prizeId, true);

        VRFCoordinatorV2_5Mock(address(vrfCoordinator)).fulfillRandomWords(1, address(IAmpleDraw(vault.prizeDraw())));

        (,, winningTicketId,,) = vault.prizePool(prizeId);
        console.log("winningTicketId", winningTicketId);
        assertGt(winningTicketId, 0, "winningTicketId should be set");
        assertLt(winningTicketId, totalTwab, "winningTicketId should be less than totalTwab");
    }

    function testFork_ClaimPrize()
        public
        whenUserHasBalance(address(USDC), DEPOSITOR, 100e6)
        whenUserHasDeposit(DEPOSITOR, 100e6)
    {
        uint256 balanceBefore = USDC.balanceOf(DEPOSITOR);
        console.log("balanceBefore", balanceBefore);

        skip(7 days);
        vm.roll(block.number + 50400); // ~7 days of blocks
        _accrueInterest();

        // Create user TWAB data for merkle tree
        PrizePoolMerkleLeaf[] memory leaves = new PrizePoolMerkleLeaf[](4);
        leaves[0] = PrizePoolMerkleLeaf({user: DEPOSITOR, twab: 100e6, ticketStart: 0, ticketEnd: 99e6});
        leaves[1] = PrizePoolMerkleLeaf({user: SUPPLIER, twab: 50e6, ticketStart: 100e6, ticketEnd: 149e6});
        leaves[2] = PrizePoolMerkleLeaf({user: RECEIVER, twab: 75e6, ticketStart: 150e6, ticketEnd: 224e6});
        leaves[3] = PrizePoolMerkleLeaf({user: ONBEHALF, twab: 25e6, ticketStart: 225e6, ticketEnd: 249e6});

        // Generate merkle root and total TWAB
        bytes32 merkleRoot = MerkleHelper.generateMerkleRoot(leaves);
        uint256 totalTwab = 250e6; // 100 + 50 + 75 + 25

        vm.prank(PRIZEKEEPER);
        uint256 prizeId = vault.setMerkleRoot(merkleRoot, totalTwab);

        vm.prank(PRIZEKEEPER);
        vault.drawWinner(prizeId, true);

        VRFCoordinatorV2_5Mock(address(vrfCoordinator)).fulfillRandomWords(1, address(IAmpleDraw(vault.prizeDraw())));

        (,, uint256 winningTicketId, uint256 prize,) = vault.prizePool(prizeId);
        console.log("prizePool.totalTwab", totalTwab);
        console.log("prizePool.winningTicketId", winningTicketId);
        console.log("prizePool.prize", prize);

        // Determine which user won based on ticket range
        uint256 winnerIndex = type(uint256).max;
        for (uint256 i = 0; i < leaves.length; i++) {
            if (winningTicketId >= leaves[i].ticketStart && winningTicketId <= leaves[i].ticketEnd) {
                winnerIndex = i;
                break;
            }
        }

        require(winnerIndex != type(uint256).max, "No winner found");
        console.log("Winner index:", winnerIndex);
        console.log("Winner address:", leaves[winnerIndex].user);

        // Generate merkle proof for winner
        bytes32[] memory merkleProof = MerkleHelper.generateMerkleProof(leaves, winnerIndex);

        address winner = leaves[winnerIndex].user;
        uint256 winnerBalanceBefore = vault.balanceOf(winner);

        vm.prank(winner);
        vault.claimPrize(prizeId, winner, leaves[winnerIndex], merkleProof);

        uint256 winnerBalanceAfter = vault.balanceOf(winner);
        console.log("winnerBalanceBefore", winnerBalanceBefore);
        console.log("winnerBalanceAfter", winnerBalanceAfter);
        assertEq(winnerBalanceAfter, winnerBalanceBefore + prize, "winner should receive exact prize amount");

        // Check prize is marked as claimed
        (,,,, bool claimed) = vault.prizePool(prizeId);
        assertTrue(claimed, "prize should be marked as claimed");

        // Check total prizes claimed by casting to concrete type
        assertEq(AmpleEarn(address(vault)).totalPrizesClaimed(), prize, "totalPrizesClaimed should be updated");
    }

    function testFork_ClaimPrize_MultipleDeposits()
        public
        whenUserHasBalance(address(USDC), DEPOSITOR, 100e6)
        whenUserHasBalance(address(USDC), SUPPLIER, 100e6)
        whenUserHasBalance(address(USDC), RECEIVER, 100e6)
        whenUserHasBalance(address(USDC), ONBEHALF, 100e6)
        whenUserHasDeposit(DEPOSITOR, 100e6)
        whenUserHasDeposit(SUPPLIER, 100e6)
        whenUserHasDeposit(RECEIVER, 100e6)
        whenUserHasDeposit(ONBEHALF, 100e6)
    {
        skip(7 days);
        vm.roll(block.number + 50400); // ~7 days of blocks
        _accrueInterest();

        uint256 currentPrize = vault.getCurrentPrizeAmount();
        console.log("currentPrize", currentPrize);
        assertGt(currentPrize, 0, "prize should have accrued");

        // Create user TWAB data for merkle tree (equal deposits, equal TWAB)
        PrizePoolMerkleLeaf[] memory leaves = new PrizePoolMerkleLeaf[](4);
        leaves[0] = PrizePoolMerkleLeaf({user: DEPOSITOR, twab: 100e6, ticketStart: 0, ticketEnd: 99e6});
        leaves[1] = PrizePoolMerkleLeaf({user: SUPPLIER, twab: 100e6, ticketStart: 100e6, ticketEnd: 199e6});
        leaves[2] = PrizePoolMerkleLeaf({user: RECEIVER, twab: 100e6, ticketStart: 200e6, ticketEnd: 299e6});
        leaves[3] = PrizePoolMerkleLeaf({user: ONBEHALF, twab: 100e6, ticketStart: 300e6, ticketEnd: 399e6});

        bytes32 merkleRoot = MerkleHelper.generateMerkleRoot(leaves);
        uint256 totalTwab = 400e6;

        vm.prank(PRIZEKEEPER);
        uint256 prizeId = vault.setMerkleRoot(merkleRoot, totalTwab);

        vm.prank(PRIZEKEEPER);
        vault.drawWinner(prizeId, true);

        VRFCoordinatorV2_5Mock(address(vrfCoordinator)).fulfillRandomWords(1, address(IAmpleDraw(vault.prizeDraw())));

        (,, uint256 winningTicketId, uint256 prize,) = vault.prizePool(prizeId);
        console.log("winningTicketId", winningTicketId);
        console.log("prize", prize);

        // Find winner
        uint256 winnerIndex = type(uint256).max;
        for (uint256 i = 0; i < leaves.length; i++) {
            if (winningTicketId >= leaves[i].ticketStart && winningTicketId <= leaves[i].ticketEnd) {
                winnerIndex = i;
                break;
            }
        }

        require(winnerIndex != type(uint256).max, "No winner found");
        console.log("Winner:", leaves[winnerIndex].user);

        bytes32[] memory merkleProof = MerkleHelper.generateMerkleProof(leaves, winnerIndex);

        address winner = leaves[winnerIndex].user;
        uint256 winnerBalanceBefore = vault.balanceOf(winner);

        vm.prank(winner);
        vault.claimPrize(prizeId, winner, leaves[winnerIndex], merkleProof);

        uint256 winnerBalanceAfter = vault.balanceOf(winner);
        assertEq(winnerBalanceAfter, winnerBalanceBefore + prize, "winner should receive prize");

        // Verify all users still have their deposits
        assertGt(vault.balanceOf(DEPOSITOR), 0, "depositor should still have shares");
        assertGt(vault.balanceOf(SUPPLIER), 0, "supplier should still have shares");
        assertGt(vault.balanceOf(RECEIVER), 0, "receiver should still have shares");
        assertGt(vault.balanceOf(ONBEHALF), 0, "onbehalf should still have shares");
    }

    function testFork_MultiplePrizeRounds()
        public
        whenUserHasBalance(address(USDC), DEPOSITOR, 200e6)
        whenUserHasDeposit(DEPOSITOR, 200e6)
    {
        // First round
        skip(7 days);
        vm.roll(block.number + 50400); // ~7 days of blocks
        _accrueInterest();

        uint256 prize1 = vault.getCurrentPrizeAmount();
        console.log("Round 1 prize:", prize1);

        PrizePoolMerkleLeaf[] memory leaves1 = new PrizePoolMerkleLeaf[](1);
        leaves1[0] = PrizePoolMerkleLeaf({user: DEPOSITOR, twab: 200e6, ticketStart: 0, ticketEnd: 199e6});

        bytes32 merkleRoot1 = MerkleHelper.generateMerkleRoot(leaves1);

        vm.prank(PRIZEKEEPER);
        uint256 prizeId1 = vault.setMerkleRoot(merkleRoot1, 200e6);

        vm.prank(PRIZEKEEPER);
        vault.drawWinner(prizeId1, true);

        VRFCoordinatorV2_5Mock(address(vrfCoordinator)).fulfillRandomWords(1, address(IAmpleDraw(vault.prizeDraw())));

        bytes32[] memory proof1 = MerkleHelper.generateMerkleProof(leaves1, 0);

        vm.prank(DEPOSITOR);
        vault.claimPrize(prizeId1, DEPOSITOR, leaves1[0], proof1);

        uint256 balanceAfterRound1 = vault.balanceOf(DEPOSITOR);
        console.log("Balance after round 1:", balanceAfterRound1);

        // Second round
        skip(7 days);
        vm.roll(block.number + 50400); // ~7 days of blocks
        _accrueInterest();

        uint256 prize2 = vault.getCurrentPrizeAmount();
        console.log("Round 2 prize:", prize2);
        assertGt(prize2, 0, "prize should have accrued again");

        PrizePoolMerkleLeaf[] memory leaves2 = new PrizePoolMerkleLeaf[](1);
        leaves2[0] = PrizePoolMerkleLeaf({user: DEPOSITOR, twab: 200e6, ticketStart: 0, ticketEnd: 199e6});

        bytes32 merkleRoot2 = MerkleHelper.generateMerkleRoot(leaves2);

        vm.prank(PRIZEKEEPER);
        uint256 prizeId2 = vault.setMerkleRoot(merkleRoot2, 200e6);

        assertEq(prizeId2, 1, "second prize ID should be 1");

        vm.prank(PRIZEKEEPER);
        vault.drawWinner(prizeId2, true);

        VRFCoordinatorV2_5Mock(address(vrfCoordinator)).fulfillRandomWords(2, address(IAmpleDraw(vault.prizeDraw())));

        bytes32[] memory proof2 = MerkleHelper.generateMerkleProof(leaves2, 0);

        vm.prank(DEPOSITOR);
        vault.claimPrize(prizeId2, DEPOSITOR, leaves2[0], proof2);

        uint256 balanceAfterRound2 = vault.balanceOf(DEPOSITOR);
        console.log("Balance after round 2:", balanceAfterRound2);

        assertGt(balanceAfterRound2, balanceAfterRound1, "balance should increase after second prize");
    }
}
