// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import {Script} from "forge-std/Script.sol";
import {StdChains} from "forge-std/StdChains.sol";
import {console} from "forge-std/console.sol";

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

abstract contract BaseScript is Script {
    /// @dev Included to enable compilation of the script without a $MNEMONIC environment variable.
    string internal constant TEST_MNEMONIC = "test test test test test test test test test test test junk";

    /// @dev Needed for the deterministic deployments.
    bytes32 internal constant ZERO_SALT = bytes32(0);

    /// @dev The address of the transaction broadcaster.
    address internal broadcaster;

    /// @dev Used to derive the broadcaster's address if $ETH_FROM is not defined.
    string internal mnemonic;

    /// @dev Initializes the transaction broadcaster like this:
    ///
    /// - If $DEPLOYER_ADDRESS is defined, use it.
    /// - Otherwise, derive the broadcaster address from $MNEMONIC.
    /// - If $MNEMONIC is not defined, default to a test mnemonic.
    ///
    /// The use case for $DEPLOYER_ADDRESS is to specify the broadcaster key and its address via the command line.
    constructor() {
        console.log(
            string.concat(
                "Deploying on Chain: ", StdChains.getChain(block.chainid).name, " (", vm.toString(block.chainid), ")"
            )
        );
        address from = vm.envOr({name: "DEPLOYER_ADDRESS", defaultValue: address(0)});
        if (from != address(0)) {
            broadcaster = from;
            console.log("DEPLOYER_ADDRESS: %s", broadcaster);
        } else {
            console.log("!!! WARNING: No DEPLOYER_ADDRESS found in .env, using MNEMONIC !!!");
            mnemonic = vm.envOr({name: "MNEMONIC", defaultValue: TEST_MNEMONIC});
            if (keccak256(bytes(mnemonic)) == keccak256(bytes(TEST_MNEMONIC))) {
                console.log("!!! WARNING: Using TEST_MNEMONIC !!!");
            }
            (broadcaster,) = deriveRememberKey({mnemonic: mnemonic, index: 0});
        }
    }

    modifier broadcast() {
        vm.startBroadcast(broadcaster);
        _;
        vm.stopBroadcast();
    }
}
