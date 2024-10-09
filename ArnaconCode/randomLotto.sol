// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RandomNumber {

    uint256 public NumOfParticipient = 0; 
    uint public endTimestampOfCompetition;
    uint public theRandomNumber;
    bool finished = false;


    constructor(uint endOfCompt) {
        endTimestampOfCompetition = endOfCompt;
    }

    // Event to announce the result
    event RandomNumberGenerated(uint256 indexed randomNumber);

    function generateRandomNumber() public returns (uint256) {
        require(block.timestamp >= endTimestampOfCompetition);
        require(!finished);

        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % NumOfParticipient + 1;
        emit RandomNumberGenerated(randomNumber);
        finished = true;

        theRandomNumber = randomNumber;
        return randomNumber;
    }

    function registerNumber() public {
        NumOfParticipient++;
    }

    function showRandomNumber() public view returns (uint) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 400 + 1;
    }

    
// 39483394596280183949655341987574958222585211648462578177318147006120435143937
// 6626371984415448063121269384823813362583627370376291567022011593735844194478

}
