// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces.sol";

contract settlements {

    constructor(){}

    mapping(address => uint) private lastPaidIndex;

    function getPaidForAllSubscription() public {
        (uint fundsToTransferToTheProvider, uint LastPaidIndex) = ISubscription(msg.sender).calculateMoneyToBePaid();
        payable(msg.sender).transfer(fundsToTransferToTheProvider); // That's to pay for the SP the deserved amount
                                                                    // No the SP will only get paid for the expired packages... not good but can be changed
        ISubscription(msg.sender).advancePaidIndex(LastPaidIndex); // update the last paid index for the service provider
    }

}
