
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts@4.9.3/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.9.3/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.9.3/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts@4.9.3/access/Ownable.sol";
import "@openzeppelin/contracts@4.9.3/utils/Counters.sol";

contract wens is ERC721, ERC721URIStorage, ERC721Burnable, Ownable{

    receive() external payable {}
    uint256 _valueToSendForRegister;
    mapping (uint256 => address) public ENS;

    // constructor(uint256 _valueForRegisterInNetwork) ERC721("WENS", "WNS") {_valueToSendForRegister = _valueForRegisterInNetwork; }
    constructor() ERC721("WENS", "WNS") {}


    function safeMint(
        address _userAddress, 
        string memory _userENS
    ) public {

        // require(msg.value >= _valueToSendForRegister, "Not enough money sent");
        require(bytes(_userENS).length != 0, "Empty ENS");

        // normalization - only name ( without domain )
        string memory userENSNormalize = toLowerCaseNormalize(_userENS);

        string memory userENSWithDomain = string(abi.encodePacked(userENSNormalize, ".web3")); 
        uint256 tokenId = uint256(keccak256(abi.encodePacked(userENSWithDomain)));

        ENS[tokenId] = _userAddress;
        
        _safeMint(_userAddress, tokenId);
        _setTokenURI(tokenId, _userENS);

    }

    // Without the ending
    function getAddress(
        string memory _userENS
    ) external view returns(address){

        string memory userENSWithDomain;

        if (endsWithWeb3(_userENS)){
            userENSWithDomain = _userENS;
        } else {
            string memory userENSNormalize = toLowerCaseNormalize(_userENS);
            userENSWithDomain = string(abi.encodePacked(userENSNormalize, ".web3")); 
        }
        
        uint256 tokenId = uint256(keccak256(abi.encodePacked(userENSWithDomain)));

        return ENS[tokenId];

    }

    function toLowerCaseNormalize(
        string memory str
    ) internal pure returns (string memory) {

        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);

        for (uint i = 0; i < bStr.length; i++) {

            if (bStr[i] == ".") {
                revert("Invalid name");
            }

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

    function endsWithWeb3(
        string memory str
    ) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        bytes memory suffix = bytes(".web3");

        // Check if the main string is shorter than the suffix
        if (strBytes.length < suffix.length) {
            return false;
        }

        // Compare the end of 'str' with '.web3'
        for (uint i = 0; i < suffix.length; i++) {
            if (strBytes[strBytes.length - suffix.length + i] != suffix[i]) {
                return false; // If any character does not match, return false
            }
        }

        return true; // If all characters match, the string ends with '.web3'
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

    // Function to withdraw the contract balance to the owner's address
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // changes the amount to be send when registering a new identity
    function changeAmountOfSender(
        uint _newAmountToChange
    ) public onlyOwner {
        _valueToSendForRegister = _newAmountToChange;
    }
    

    // Function to convert address to string
    function toString(
        address account
    ) internal pure returns(string memory) {
        bytes32 value = bytes32(uint256(uint160(account)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42); // 2 character prefix and 40 characters for address

        str[0] = '0';
        str[1] = 'x';

        for (uint256 i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }

        return string(str);
    }

    function isAddress(
        string memory _addr
    ) internal pure returns (bool) {

        // Address are exactly 42 characters long
        if(bytes(_addr).length != 42) return false;

        // Convert string to bytes
        bytes memory tempEmptyStringTest = bytes(_addr);
        if(tempEmptyStringTest.length == 0) return false;

        // Check prefix
        if(tempEmptyStringTest[0] != '0' || tempEmptyStringTest[1] != 'x') return false;

        // Check each character
        for(uint i = 2; i < 42; i++){
            // Check if each character is valid (0-9, a-f, A-F)
            bytes1 char = tempEmptyStringTest[i];
            if(
                !(char >= 0x30 && char <= 0x39) && // 0-9
                !(char >= 0x41 && char <= 0x46) && // A-F
                !(char >= 0x61 && char <= 0x66)    // a-f
            )
                return false;
        }

        // If all checks passed, it's a valid address format
        return true;
    }

}
