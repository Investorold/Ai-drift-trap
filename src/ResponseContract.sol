// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ResponseContract {
    string public lastMessage;

    function handleDrift(string memory _message) public {
        lastMessage = _message;
    }
}
