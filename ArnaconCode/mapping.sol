// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts@4.9.3/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.9.3/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.9.3/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts@4.9.3/access/Ownable.sol";
import "@openzeppelin/contracts@4.9.3/utils/Counters.sol";

contract Mapping is ERC721, ERC721URIStorage, ERC721Burnable, Ownable{

    mapping(string => string) public  productToAddressCCounter;

    constructor() ERC721("Mapping", "MAP") {}

    function safeMint(address to, uint productCounter, string memory _userProduct) public onlyOwner{ // User product can be matan6

        uint256 tokenId = uint256(
                            keccak256(
                                abi.encodePacked(
                                    to, 
                                    productCounter
                            ))); // Address (concat) counter = 0xA4aA...4C 5 ( product counter - 5)

        if (_exists(tokenId)) {
            revert("NFT Already exists");
        }

        _safeMint(msg.sender, tokenId);

        _setTokenURI(tokenId, _userProduct);

        productToAddressCCounter[_userProduct] = string(
                                                    abi.encodePacked(
                                                        addressToString(to), 
                                                        uintToString(productCounter)
                                                    )); // Will map ens ==> address (concat) counter
    }

    function getProductFromAddress(
        address _userAddress, 
        uint256 _productCounter
    ) public view returns(string memory) {

        uint256 tokenId = uint256(keccak256(abi.encodePacked(_userAddress, _productCounter)));
        return tokenURI(tokenId);
    }

    function getProductFromAddressProduct(
        string memory addressAndCounter
    ) public view returns(string memory) {

        uint256 tokenId = uint256(keccak256(abi.encode(addressAndCounter)));
        return tokenURI(tokenId);
    }
    
    

    function addressToString(
        address account
    ) internal pure returns(string memory) {

        bytes memory data = abi.encodePacked(account);
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function toLowerCase(
        string memory str
    ) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase characters are between 65 ('A') and 90 ('Z')
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // Convert uppercase to lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                // Else, keep the character unchanged
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    // Function to convert uint to string
    function uintToString(
        uint256 value
    ) internal pure returns (string memory) {
        // Base case
        if (value == 0) {
            return "0";
        }

        // Determine the length of the resulting string
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        // Allocate enough space to store the string
        bytes memory buffer = new bytes(digits);

        // Fill the buffer with the digits of the value
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }

        return string(buffer);
    }
    
    // The following functions are overrides required by Solidity:
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

