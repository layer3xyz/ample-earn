// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import {IERC20} from "openzeppelin-contracts/interfaces/IERC20.sol";

import {console} from "forge-std/console.sol";
import {BaseScript} from "../BaseScript.s.sol";

import {AmpleEarn} from "../../../src/ample/AmpleEarn.sol";

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

/// @title PublicScript
/// @notice Script for public functions of Ample Money contracts
contract PublicScript is BaseScript {
    AmpleEarn public ampleEarn;
    IERC20 public asset;
    IERC20 public share;

    function deposit() external broadcast logAmpleEarnDetails {
        console.log("\n=== Depositing to AmpleEarn ===\n");
        // Get amount from environment variable (in asset's base units, e.g., USDC has 6 decimals)
        uint256 amount = vm.envUint("AMOUNT");

        // Get recipient address, default to broadcaster if not specified
        address receiver = vm.envOr("RECEIVER", broadcaster);

        if (receiver == broadcaster) {
            console.log("!!! WARNING: Using broadcaster as receiver !!!\n");
        } else {
            console.log("!!! WARNING: Using specified receiver !!!\n");
        }

        console.log("Broadcaster asset balance before:", asset.balanceOf(broadcaster));
        console.log("Receiver share balance before:", share.balanceOf(receiver), "\n");

        console.log(
            string.concat(
                "1. Approving ",
                vm.toString(amount),
                " of ",
                vm.toString(ampleEarn.asset()),
                " to ",
                vm.toString(address(ampleEarn))
            )
        );
        asset.approve(address(ampleEarn), amount);

        console.log(
            string.concat(
                "2. Depositing ",
                vm.toString(amount),
                " of ",
                vm.toString(ampleEarn.asset()),
                " for ",
                vm.toString(receiver),
                "\n"
            )
        );
        ampleEarn.deposit(amount, receiver);

        console.log("Broadcaster asset balance after:", asset.balanceOf(broadcaster));
        console.log("Receiver share balance after:", share.balanceOf(broadcaster));

        console.log("\n=== Deposit Complete ===\n");
    }

    modifier logAmpleEarnDetails() {
        ampleEarn = AmpleEarn(vm.envAddress("AMPLE_EARN"));
        asset = IERC20(ampleEarn.asset());
        share = IERC20(ampleEarn);

        console.log("\n=== AmpleEarn Details ===");

        console.log("Address:", address(ampleEarn));
        console.log("Owner:", ampleEarn.owner());
        console.log("Asset:", ampleEarn.asset());
        console.log("Name:", ampleEarn.name());
        console.log("Symbol:", ampleEarn.symbol());
        console.log("Timelock:", ampleEarn.timelock());
        console.log("PrizeDraw:", address(ampleEarn.prizeDraw()));
        console.log("Current Prize ID:", ampleEarn.currentPrizeId());
        console.log("Total Prizes Claimed:", ampleEarn.totalPrizesClaimed());
        console.log("Total Prizes Locked:", ampleEarn.totalPrizesLocked());
        console.log("Current Prize Amount:", ampleEarn.totalAssets() - ampleEarn.lastTotalAssets());


        console.log(
            string.concat(
                "\nView on Euler Earn: https://earn.euler.finance/euler-earn/vault/",
                vm.toString(block.chainid),
                "/",
                vm.toString(address(ampleEarn))
            )
        );
        _;
    }
}
