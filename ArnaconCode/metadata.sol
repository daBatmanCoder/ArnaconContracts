// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts@4.9.3/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.9.3/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.9.3/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts@4.9.3/access/Ownable.sol";
import "@openzeppelin/contracts@4.9.3/utils/Counters.sol";


contract Metadata is ERC721, ERC721URIStorage, ERC721Burnable, Ownable{

    uint256                     valueToSendForData;
    using Counters   for        Counters.Counter;
    Counters.Counter private    _tokenIdCounter;


    // constructor(uint256 _valueToSendForData) ERC721("Metadata", "MDA") {
    //     valueToSendForData = _valueToSendForData;
    constructor() ERC721("Metadata", "MDA") { }


    function safeMint(
        address _to,
        string memory _metadata
    ) public payable returns(uint){ 
        // require(
        //     msg.value >= valueToSendForData,
        //     "Not enough money was sent"
        // );

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _metadata);
        return tokenId;
    }

    function safeMintIndex(
        address _to,
        string memory _metadata,
        uint256 _index // Since every GSM number has the country code and there are 2 identical numbers in the world we're good ( AMIR )
    ) public{ 
        // require(
        //     msg.value >= valueToSendForData,
        //     "Not enough money was sent"
        // );

        uint256 tokenId = _index;
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _metadata);
    }

    // The following functions are overrides required by Solidity:
    function _burn(
        uint256 tokenId
    ) internal
     override(ERC721, ERC721URIStorage) {

        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    )
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

        valueToSendForData = _newAmountToChange;
    }
}

// { 'name': 'cellact NL', 'domain':'test.cellact.nl' }
