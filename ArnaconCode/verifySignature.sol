// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract VerifySignature {

    function verifySignature(address user, string memory message, bytes memory signature)
        external
        pure
        returns (bool)
    {   
        
        bytes32 hashedMessage = computeHash(message);
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
        return ecrecover(hashedMessage, v, r, s) == user;
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
