// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {PrizePoolMerkleLeaf} from "../../src/ample/interfaces/IAmpleEarn.sol";
import {MerkleHelper} from "../../test/ample/helpers/MerkleHelper.sol";

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

contract GenerateMerkleRootScript is Script {
    function run() external pure {
        console.log("=== Generating Merkle Root with 3 Example Leaves ===\n");

        // Define 3 example users with their TWAB data
        PrizePoolMerkleLeaf[] memory leaves = new PrizePoolMerkleLeaf[](3);

        // User 1: Alice with 100 TWAB, tickets 0-99
        leaves[0] = PrizePoolMerkleLeaf({
            user: address(0x2A5ef96E7D5537D777A0dc53FdbF7a23545CEd9b), twab: 100e6, ticketStart: 0, ticketEnd: 99e6
        });

        // User 2: Bob with 50 TWAB, tickets 100-149
        leaves[1] = PrizePoolMerkleLeaf({
            user: address(0x2A5ef96E7D5537D777A0dc53FdbF7a23545CEd9b), twab: 50e6, ticketStart: 100e6, ticketEnd: 149e6
        });

        // User 3: Charlie with 75 TWAB, tickets 150-224
        leaves[2] = PrizePoolMerkleLeaf({
            user: address(0x2A5ef96E7D5537D777A0dc53FdbF7a23545CEd9b), twab: 75e6, ticketStart: 150e6, ticketEnd: 224e6
        });

        // Calculate total TWAB
        uint256 totalTwab = 225e6; // 100 + 50 + 75

        console.log("Leaf Data:");
        console.log("----------");
        for (uint256 i = 0; i < leaves.length; i++) {
            console.log("Leaf", i);
            console.log("  User:", leaves[i].user);
            console.log("  TWAB:", leaves[i].twab);
            console.log("  Ticket Start:", leaves[i].ticketStart);
            console.log("  Ticket End:", leaves[i].ticketEnd);
            console.log("");
        }

        console.log("Total TWAB:", totalTwab);
        console.log("");

        // Generate merkle root
        bytes32 merkleRoot = MerkleHelper.generateMerkleRoot(leaves);

        console.log("Generated Merkle Root:");
        console.logBytes32(merkleRoot);
        console.log("");

        // Generate proofs for each leaf
        console.log("Merkle Proofs:");
        console.log("--------------");
        for (uint256 i = 0; i < leaves.length; i++) {
            bytes32[] memory proof = MerkleHelper.generateMerkleProof(leaves, i);
            console.log("Proof for Leaf", i);
            console.log("  User:", leaves[i].user);
            console.log("  Proof length:", proof.length);
            for (uint256 j = 0; j < proof.length; j++) {
                console.log("  Proof", j);
                console.logBytes32(proof[j]);
            }
            console.log("");
        }

        console.log("=== Summary ===");
        console.log("Merkle Root (bytes32):");
        console.logBytes32(merkleRoot);
        console.log("Total TWAB:", totalTwab);
        console.log("Number of leaves:", leaves.length);
    }
}
