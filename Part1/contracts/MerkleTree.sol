//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract

contract MerkleTree is Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root

    constructor() {
        uint leavesNum = 8;
        for (uint i = 0; i < leavesNum; i++) {
            hashes.push(0);
        }

        uint offset = 0;

        while (leavesNum > 0) {
            for (uint i = 0; i < leavesNum - 1; i += 2) {
                hashes.push(PoseidonT3.poseidon([hashes[offset + i], hashes[offset + i + 1]]));
            }
            offset += leavesNum;
            leavesNum = leavesNum / 2;
        }

        root = hashes[hashes.length - 1];
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        hashes[index] = hashedLeaf;

        uint _index = index;
        uint offset = 0;
        uint leavesNum = 8;

        while (leavesNum > 1) {
            if (_index % 2 == 0) {
                hashedLeaf = PoseidonT3.poseidon([hashedLeaf, hashes[offset + _index + 1]]);
            } else {
                hashedLeaf = PoseidonT3.poseidon([hashes[offset + _index - 1], hashedLeaf]);
            }

            offset += leavesNum;
            leavesNum = leavesNum / 2;
            _index = _index / 2;

            hashes[offset + _index] = hashedLeaf;
        }
        

        root = hashes[hashes.length - 1];
        index += 1;

        return root;
    }

    function verify(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[1] memory input
        ) public view returns (bool) {

        if (input[0] == root) {
            return Verifier.verifyProof(a, b, c, input);
        }

        return false;
    }
}

