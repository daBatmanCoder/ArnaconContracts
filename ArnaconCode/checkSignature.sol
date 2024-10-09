// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract SignatureVerifier {
    // Function to verify the message and recover the signer's address
    function verify(string memory message, bytes memory signature) public pure returns (address) {
        // Recreate the message hash as it was hashed off-chain
        bytes32 messageHash = keccak256(abi.encodePacked(message));

        // Recreate the hash that was actually signed (Ethereum Signed Message)
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        // Recover the signer's address
        return recoverSigner(ethSignedMessageHash, signature);
    }

    // Function to add the Ethereum prefix and hash the message hash
    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        /*
          The prefix "\x19Ethereum Signed Message:\n" is used to prevent the same
          signed data from being used in a transaction to execute unintended operations.
        */
        return keccak256(abi.encodePacked(_messageHash));
    }

    // Function to split the signature and recover the signer's address
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    // Helper function to split the signature into r, s, and v components
    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            // First 32 bytes stores the length of the signature

            // Next 32 bytes is the r component
            r := mload(add(sig, 32))
            // Next 32 bytes is the s component
            s := mload(add(sig, 64))
            // Final byte (first byte of the next 32 bytes) is the v component
            v := byte(0, mload(add(sig, 96)))
        }

        // If the v value is not 27 or 28, it's likely in Ethereum's "short" format, so add 27 to it
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "invalid signature 'v' value");
    }
}
