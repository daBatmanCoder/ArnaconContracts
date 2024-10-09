// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "./structs.sol";

interface IENS {

    function owner(
        bytes32 node
    ) external view returns(address); // without the .web3
}

interface INameHash {
        function namehash(string memory name) external pure returns (bytes32);
}

interface IDorot {
    
    function ayalaVersion(
        bytes       memory  _signature, 
        string      memory  _commitment,
        bytes32             _node, // namehash of ENS
        address _ayalaAddress 
    ) external;
}

interface IServiceProviders {

    function safeMint(
        bytes32 _serviceProviderName,
        address _addressOfContract
    ) external payable;

}

interface IAyala {

    function updateUserRegistery(
        bytes   memory _signature, 
        string  memory _messageSigned, 
        bytes32        _ENS 
    ) external;

    function updateUser(
        bytes32 _ENS
    ) external;

    function getENSToServiceProvider(
        bytes32 _ENS
    ) external view returns (address);

    function updateUserRegistryWithCommitmentCheck(
        bytes       memory  _signature, 
        string      memory  _commitment, 
        bytes32             _node
    ) external;
}

interface IMetadata {

    function tokenURI(
        uint256 tokenId
    ) external view returns (string memory);

    function safeMint(
        address         _to, 
        string memory   _metadata
    ) external payable returns(uint);

    function safeMintIndex(
        address         _to, 
        string memory   _metadata,
        uint256 _index
    ) external;

    function _burn(
        uint256 tokenId
    ) external;
}

interface IVerifier {

    function verifyProof(
        uint[2] memory      a,
        uint[2][2] memory   b,
        uint[2] memory      c,
        uint[2] memory      input
    ) external pure returns (bool r);

}

interface IVerifierSignature {

    function verifySignature(
        address         user, 
        string memory   message,
        bytes memory    signature
    ) external pure returns (bool);

}

interface IPalo {

    function directTransfer(
        address recipient, 
        uint256 amount
    ) external;

    function directTransferFContract(
        address recipient, 
        uint256 amount
    ) external;

    function balanceOf(
        address account
    ) external view returns(uint256);

    function transferFrom(
        address from,
        address to,
        uint amount
    ) external;

} 

interface ISubscription{

    function calculateMoneyToBePaid() external returns(uint,uint);
    function advancePaidIndex(uint _newIndex) external;
}

interface IProducts {
    function getSingleProduct(uint256 _productID) external view returns(singleProduct memory);
}

interface IServiceProvider {
    function getServiceProviderDomain() external view returns(string memory);
    function getUserPublicKey(bytes32 _ENSNode)external view returns(string memory);
}