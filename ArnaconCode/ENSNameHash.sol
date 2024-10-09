// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract ENSNamehash {
    /**
     * @dev Computes the ENS namehash of a domain name recursively.
     * @param name The full ENS name (e.g., "subdomain.domain.eth").
     * @return The namehash of the ENS name.
     */
    function namehash(string memory name) public pure returns (bytes32) {
        // The hash of an empty name ('') is defined as 0x00.
        bytes32 hash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        
        // Only proceed if the name is not empty.
        if (bytes(name).length == 0) {
            return hash;
        }

        // Split the name by '.' to isolate parts from right to left
        string[] memory parts = split(name, '.');

        // Start from the TLD and move left
        for (int256 i = int256(parts.length) - 1; i >= 0; i--) {
            bytes32 labelHash = keccak256(abi.encodePacked(parts[uint256(i)]));
            hash = keccak256(abi.encodePacked(hash, labelHash));
        }

        return hash;
    }

    /**
     * @dev Splits a string by a delimiter.
     * @param source The string to split.
     * @param delimiter The delimiter to use for splitting the string.
     * @return parts An array of substrings.
     */
    function split(string memory source, string memory delimiter) internal pure returns (string[] memory) {
        string[] memory partss;
        if (bytes(source).length == 0) {
            return partss;
        }

        // Count the splits
        uint256 count = 1;
        for (uint256 i = 0; i < bytes(source).length - 1; i++) {
            if (bytes(source)[i] == bytes(delimiter)[0]) {
                count++;
            }
        }

        string[] memory parts = new string[](count);
        uint256 index = 0;
        uint256 lastIndex = 0;

        // Split the string by finding instances of the delimiter
        for (uint256 i = 0; i <= bytes(source).length - 1; i++) {
            if (bytes(source)[i] == bytes(delimiter)[0]) {
                parts[index] = substring(source, lastIndex, i);
                index++;
                lastIndex = i + 1;
            }
        }

        // Add the last part
        parts[index] = substring(source, lastIndex, bytes(source).length);
        return parts;
    }

    /**
     * @dev Extracts a substring from a given string.
     * @param str The original string.
     * @param startIndex The start index of the substring.
     * @param endIndex The end index of the substring.
     * @return substring The extracted substring.
     */
    function substring(string memory str, uint256 startIndex, uint256 endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }
}
