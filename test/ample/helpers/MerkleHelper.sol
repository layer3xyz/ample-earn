// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

import {PrizePoolMerkleLeaf} from "../../../src/ample/interfaces/IAmpleEarn.sol";

library MerkleHelper {
    /**
     * @notice Generates a merkle tree from user TWAB data
     * @param leaves Array of user TWAB data to include in the merkle tree
     * @return merkleRoot The root of the generated merkle tree
     */
    function generateMerkleRoot(PrizePoolMerkleLeaf[] memory leaves) internal pure returns (bytes32) {
        require(leaves.length > 0, "No leaves provided");

        // Generate leaf hashes
        bytes32[] memory leafHashes = new bytes32[](leaves.length);
        for (uint256 i = 0; i < leaves.length; i++) {
            leafHashes[i] =
                keccak256(abi.encode(leaves[i].user, leaves[i].twab, leaves[i].ticketStart, leaves[i].ticketEnd));
        }

        return _calculateMerkleRoot(leafHashes);
    }

    /**
     * @notice Generates a merkle proof for a specific leaf
     * @param leaves Array of user TWAB data
     * @param targetIndex Index of the leaf to generate proof for
     * @return proof The merkle proof for the target leaf
     */
    function generateMerkleProof(PrizePoolMerkleLeaf[] memory leaves, uint256 targetIndex)
        internal
        pure
        returns (bytes32[] memory)
    {
        require(targetIndex < leaves.length, "Invalid target index");

        // Generate leaf hashes
        bytes32[] memory leafHashes = new bytes32[](leaves.length);
        for (uint256 i = 0; i < leaves.length; i++) {
            leafHashes[i] =
                keccak256(abi.encode(leaves[i].user, leaves[i].twab, leaves[i].ticketStart, leaves[i].ticketEnd));
        }

        return _generateProof(leafHashes, targetIndex);
    }

    /**
     * @notice Calculates merkle root from an array of leaf hashes
     * @dev Uses a standard approach compatible with OpenZeppelin
     */
    function _calculateMerkleRoot(bytes32[] memory leaves) private pure returns (bytes32) {
        uint256 n = leaves.length;
        if (n == 0) revert("Empty leaves array");

        while (n > 1) {
            uint256 k = 0;
            for (uint256 i = 0; i < n; i += 2) {
                bytes32 a = leaves[i];
                bytes32 b = (i + 1 < n) ? leaves[i + 1] : bytes32(0);
                leaves[k++] = _hashPair(a, b);
            }
            n = k;
        }

        return leaves[0];
    }

    /**
     * @notice Hash a pair of nodes, compatible with OpenZeppelin ordering
     */
    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? keccak256(abi.encodePacked(a, b)) : keccak256(abi.encodePacked(b, a));
    }

    /**
     * @notice Generates a merkle proof for a specific leaf index
     * @dev Compatible with OpenZeppelin MerkleProof verification
     */
    function _generateProof(bytes32[] memory leaves, uint256 targetIndex) private pure returns (bytes32[] memory) {
        uint256 n = leaves.length;
        if (n == 0) revert("Empty leaves array");
        if (targetIndex >= n) revert("Target index out of bounds");
        if (n == 1) return new bytes32[](0);

        // Calculate max proof length (tree height)
        uint256 maxProofLength = 0;
        uint256 temp = n;
        while (temp > 1) {
            maxProofLength++;
            temp = (temp + 1) / 2;
        }

        bytes32[] memory proof = new bytes32[](maxProofLength);
        uint256 proofLength = 0;
        uint256 currentIndex = targetIndex;

        // Make a copy of leaves to avoid modifying the original
        bytes32[] memory tree = new bytes32[](n);
        for (uint256 i = 0; i < n; i++) {
            tree[i] = leaves[i];
        }

        uint256 currentN = n;

        // Build proof by traversing up the tree
        while (currentN > 1) {
            // Find sibling
            uint256 siblingIndex;
            if (currentIndex % 2 == 0) {
                // Current is left child, sibling is right
                siblingIndex = currentIndex + 1;
            } else {
                // Current is right child, sibling is left
                siblingIndex = currentIndex - 1;
            }

            // Add sibling to proof if it exists
            if (siblingIndex < currentN) {
                proof[proofLength] = tree[siblingIndex];
            } else {
                proof[proofLength] = bytes32(0);
            }
            proofLength++;

            // Build next level
            uint256 nextN = (currentN + 1) / 2;
            for (uint256 i = 0; i < nextN; i++) {
                uint256 leftChild = 2 * i;
                uint256 rightChild = leftChild + 1;

                bytes32 left = tree[leftChild];
                bytes32 right = (rightChild < currentN) ? tree[rightChild] : bytes32(0);
                tree[i] = _hashPair(left, right);
            }

            currentIndex = currentIndex / 2;
            currentN = nextN;
        }

        // Resize proof to actual length
        bytes32[] memory finalProof = new bytes32[](proofLength);
        for (uint256 i = 0; i < proofLength; i++) {
            finalProof[i] = proof[i];
        }

        return finalProof;
    }
}
