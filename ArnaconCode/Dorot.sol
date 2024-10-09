// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./merkleTree.sol";
import "./interfaces.sol";
import "./ENSNameHash.sol";

contract Dorot {
    
    IENS                public immutable ens;
    address OWNER;
    mapping(bytes32 =>      address)   public dorot;

    event versionDoc(
        address sender,
        address recipient,
        uint256 amount
    );
    
    
    constructor(
        IENS            _ens 
    ) {
        ens = _ens;
        OWNER = msg.sender;
    }

    function ayalaVersion(
        bytes       memory  _signature, 
        string      memory  _commitment,
        bytes32             _node, // namehash of ENS
        address             _ayalaAddress 
    ) external {

        address userAddress = ens.owner(_node); 

        require(
            verifySignature(userAddress,_commitment, _signature),
            "The user didn't give you the permission to change his registry"
        );

        // emit versionDoc(msg.sender, msg.value, reciepit);

        dorot[_node] = _ayalaAddress;
    }

    function verifySignature(address user, string memory message, bytes memory signature)
        public
        pure
        returns (bool)
    {   
        return extractUserAddress(message, signature) == user;
    }

    function extractUserAddress(
        string memory message, 
        bytes memory signature
    ) internal pure returns(address){

        bytes32 hashedMessage = computeHash(message);
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
        return ecrecover(hashedMessage, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function bytes32ToBytes(bytes32 data) public pure returns (bytes memory) {
        bytes memory result = new bytes(32);
        assembly {
            mstore(add(result, 32), data)
        }
        return result;
    }

    function computeHash(string memory message)
        public 
        pure 
        returns
        (bytes32)
    {
        
        uint256 length = bytes(message).length;

        bytes memory prefix = "\x19Ethereum Signed Message:\n";
        bytes memory messageLength = uintToString(length);
        return keccak256((abi.encodePacked(prefix, messageLength, message)));
    }


    function uintToString(uint _i) 
        internal 
        pure 
        returns 
        (bytes memory) 
    {

        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }

        return bstr;
    }


}
