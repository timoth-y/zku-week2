pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mux1.circom";


template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    var total_leaves = 2**n;
    signal input leaves[total_leaves];
    signal output root;
    
    var total_hashers_num = total_leaves - 1;
    var leaf_hashers_num = total_leaves / 2;
    var middle_hashers_num = leaf_hashers_num - 1;


    component hashers[total_hashers_num];

    for (var i=0; i < total_hashers_num; i++) {
        hashers[i] = HashLeftRight();
    }

    for (var i=0; i < leaf_hashers_num; i++){
        hashers[i].left <== leaves[i*2];
        hashers[i].right <== leaves[i*2+1];
    }

    var k = 0;
    for (var i=leaf_hashers_num; i < leaf_hashers_num + middle_hashers_num; i++) {
        hashers[i].left <== hashers[k*2].hash;
        hashers[i].right <== hashers[k*2+1].hash;
        k++;
    }

    root <== hashers[total_hashers_num-1].hash;
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root;

    component hashers[n];
    component mux[n];

    signal hashes[n + 1];
    hashes[0] <== leaf;

    for (var i = 0; i < n; i++) {
        // Assert that path_index is either 0 or 1.
        path_index[i] * (1 - path_index[i]) === 0;

        hashers[i] = HashLeftRight();
        mux[i] = MultiMux1(2);

        mux[i].c[0][0] <== hashes[i];
        mux[i].c[0][1] <== path_elements[i];

        mux[i].c[1][0] <== path_elements[i];
        mux[i].c[1][1] <== hashes[i];

        mux[i].s <== path_index[i];

        hashers[i].left <== mux[i].out[0];
        hashers[i].right <== mux[i].out[1];

        hashes[i + 1] <== hashers[i].hash;
    }

    root <== hashes[n];
}

template HashLeftRight() {
    signal input left;
    signal input right;

    signal output hash;

    component hasher = Poseidon(2);
    left ==> hasher.inputs[0];
    right ==> hasher.inputs[1];

    hash <== hasher.out;
}