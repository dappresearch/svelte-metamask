// SPDX-License-Identifier

// Deployed contract
pragma solidity ^0.8.20;

contract Count {

    int256 public count;

    function plus() public {
        count++;
    }
    
    function minus() public {
        count--;
    }
}