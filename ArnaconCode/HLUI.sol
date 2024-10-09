// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts@4.9.3/access/Ownable.sol";

import "./interfaces.sol";
import "./ENSNameHash.sol";


// Read only contract that will be the main UI to call different contracts
contract HLUI is Ownable {

    IAyala      public ayalaContract;
    INameHash   public namehashContract;


    constructor(
        IAyala      _ayalaAdress,
        INameHash   _namehashAddress
    ) {
        ayalaContract = _ayalaAdress;
        namehashContract = _namehashAddress;

    }

    function updateAyala (address _newAyalaAddress) external onlyOwner {
        ayalaContract = IAyala(_newAyalaAddress);
    }

    function getUserPublicKeyRSA(string memory userENS) external view returns(string memory){

        bytes32 namehashOfENS = namehashContract.namehash(toLowerCase(userENS));
        
        address SPAddress = ayalaContract.getENSToServiceProvider(namehashOfENS);

        if (SPAddress == 0x0000000000000000000000000000000000000000){
            revert("Invalid ENS");
        }
        return IServiceProvider(SPAddress).getUserPublicKey(namehashOfENS);
    }

    function getServiceProviderDomain(string memory userENS) external view returns(string memory){

        bytes32 namehashOfENS = namehashContract.namehash(toLowerCase(userENS));
        
        address SPAddress = ayalaContract.getENSToServiceProvider(namehashOfENS);

        if (SPAddress == 0x0000000000000000000000000000000000000000){
            revert("Invalid ENS");
        }
        return IServiceProvider(SPAddress).getServiceProviderDomain();
    }

    function toLowerCase(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // If it's an uppercase letter
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // Convert to lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                // Else keep it as is
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

}