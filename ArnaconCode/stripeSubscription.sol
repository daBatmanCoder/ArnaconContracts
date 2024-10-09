// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.24;

import "./merkleTree.sol";
import "./interfaces.sol";
import "./products.sol";

contract stripeSubscription is MerkleTreeWithHistory {

    mapping(bytes32 =>  bool)               public nullifiers;
    mapping(bytes32 =>  bool)               public commitments;
    mapping(bytes32 =>  uint256)            public TTL;
    mapping(string =>   bytes32)            public userNullifierHash;


    uint SETUP_FEE      =  2;
    uint GRACE_PERIOD   =  3 days;
    uint MONTHLY_FEE    =  10;
    uint PERIOD         =  30;


    IVerifier   public immutable verifier;
    IPalo       public immutable fundsContract;

    Products productsContract;

    event Commit(
        bytes32 indexed commitment,
        uint32 leafIndex,
        uint256 timestamp
    );

    constructor(
        uint32      _levels,
        IHasher     _hasher,
        IVerifier   _verifier,
        IPalo       _fundsContract,
        Products    _productsContract
    ) MerkleTreeWithHistory(_levels, _hasher) {
        verifier            = _verifier;
        fundsContract       = _fundsContract;
        productsContract    = _productsContract;
    }


    function _createSubscription(
        bytes32 _commitmentDeposit, 
        uint _productID // 0
    ) external {

        require(!commitments[_commitmentDeposit], "The commitment has been submitted");

        uint setupFee =     productsContract.getSingleProduct(_productID).setupFee; // 2
        uint monthlyFee =   productsContract.getSingleProduct(_productID).monthlyFee; // 6

        uint moneyToSend;

        if((monthlyFee + setupFee) == 0){
            moneyToSend = 0;
        }
        else{
            moneyToSend =  monthlyFee + setupFee;
        }

        commitments[_commitmentDeposit] = true;
        
        uint32 insertedIndex = _insert(_commitmentDeposit);

        emit Commit(_commitmentDeposit, insertedIndex, block.number); 

        fundsContract.directTransfer(
            address(this),
            moneyToSend * 10 ** 18
        );
        
    }

    function _startSubscription(
        uint[2] memory      _proof_a,
        uint[2][2] memory   _proof_b,
        uint[2] memory      _proof_c,
        bytes32             _nullifierHash,
        bytes32             _root,
        string memory       _userENS
    ) external {
        require(isKnownRoot(_root), "Cannot find your merkle root");
        require(
            verifier.verifyProof(
                _proof_a,
                _proof_b,
                _proof_c,
                [uint256(_nullifierHash), uint256(_root)]
            ),
            "Invalid proof"
        );

        require(bytes32(TTL[_nullifierHash]) == 0, "package already activated"); // Because it already has an owner

        userNullifierHash[_userENS] = _nullifierHash;

        uint packageExpiringTime = block.timestamp + 30 days + GRACE_PERIOD; 

        TTL[_nullifierHash] = packageExpiringTime;
    }

    function _extendSubscription(
        uint[2] memory      _proof_a,
        uint[2][2] memory   _proof_b,
        uint[2] memory      _proof_c,
        bytes32             _nullifierHash,
        bytes32             _root,
        uint256             _productID
    ) external {

        require(isKnownRoot(_root), "Cannot find your merkle root");
        require(
            verifier.verifyProof(
                _proof_a,
                _proof_b,
                _proof_c,
                [uint256(_nullifierHash), uint256(_root)]
            ),
            "Invalid proof"
        );

        require(bytes32(TTL[_nullifierHash]) != 0, "package hasn't activated yet.");


        if ( TTL[_nullifierHash] >= block.timestamp){ // The TTL hasn't passed
             TTL[_nullifierHash] += 30 days; // adding 30 days
        } else {
            if ( TTL[_nullifierHash] + (30 days - GRACE_PERIOD) >= block.timestamp){ // Lower then the cool down time then he can extend 
                TTL[_nullifierHash] = block.timestamp + 30 days;
            }
            else{
                revert("The cool down period as passed"); // Add Error
            }
        }

        uint extensionMoney = productsContract.getSingleProduct(uint256(_productID)).monthlyFee;

        fundsContract.directTransfer(
            address(this),
            extensionMoney * 10 ** 18
        );

    }

    function calculateMoneyToBePaid(
    ) public view returns(uint){
        
        return fundsContract.balanceOf(address(this));
    }

    function isUserValid(
        string memory userENS
    ) external 
    view returns(bool){

        return TTL[userNullifierHash[userENS]] >= block.timestamp;
    }
}