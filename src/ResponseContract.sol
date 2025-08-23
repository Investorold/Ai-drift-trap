// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ResponseContract {
    address public owner;
    address public droseraAddress;
    string public lastMessage;

    event DriftDetected(string message, uint256 timestamp);
    event DroseraAddressSet(address indexed newDroseraAddress);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier onlyDrosera() {
        require(msg.sender == droseraAddress, "Caller is not the Drosera address");
        _;
    }

    function setDroseraAddress(address _newDroseraAddress) public onlyOwner {
        droseraAddress = _newDroseraAddress;
        emit DroseraAddressSet(_newDroseraAddress);
    }

    function handleDrift(string memory _message) public onlyDrosera {
        lastMessage = _message;
        emit DriftDetected(_message, block.timestamp);
    }
}
