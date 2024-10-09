// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// PALO
contract PALO is ERC20, Ownable {

    mapping(address => bool) public trustedContract;

    constructor(
        uint256 initialSupply
    ) ERC20("PALO", "PAL") Ownable(msg.sender){
        _mint(address(this), initialSupply);
    }

    function approveSpender(
        address _trustedContract
    ) external onlyOwner {

        trustedContract[_trustedContract] = true;
    }

    function directTransferFContract(
        address recipient, 
        uint256 amount
    ) external {

        // require(trustedContract[msg.sender], "Unauthorized");
        _transfer(address(this), recipient, amount);
    }

    function directTransfer(
        address recipient, 
        uint256 amount
    ) external {
        
        // require(trustedContract[msg.sender], "Unauthorized");
        _transfer(msg.sender, recipient, amount);
    } 
}
