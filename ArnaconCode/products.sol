// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "./metadata.sol";
import "./interfaces.sol";
import "./structs.sol";


contract Products {

    mapping(uint256 => singleProduct) private productsList;


    IMetadata MetadataContract;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;


    constructor(
        IMetadata _metadataContract
    ) {
        MetadataContract = _metadataContract;
    }
    
    function _addProduct(
        uint            _setupFee, 
        uint            _monthlyFee, 
        string memory   _metaData,
        address         productSenderOwner
    ) public payable {

        uint productIndexInMetadata = MetadataContract.safeMint{value: msg.value}(productSenderOwner ,_metaData);
    
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        singleProduct memory sp = singleProduct(_setupFee, _monthlyFee, productIndexInMetadata);
        productsList[tokenId] = sp;
    }


    function _getProductMetaData(
        uint256 _productID
    ) external view returns(string memory){

        uint indexInMetadata = productsList[_productID].productIndexForMetaData;

        return MetadataContract.tokenURI(indexInMetadata);
    }

    function getSingleProduct(
        uint256 _productID
    ) public view returns(singleProduct memory){
        return productsList[_productID];
    }
    
}
