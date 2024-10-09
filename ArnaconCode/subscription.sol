// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.24;

import "./merkleTree.sol";
import "./interfaces.sol";

contract Subscription is MerkleTreeWithHistory {


    mapping(bytes32 =>  bool)               public nullifiers;
    mapping(bytes32 =>  bool)               public commitments;
    mapping(bytes32 =>  bool)               public isPaid;
    mapping(bytes32 =>  uint)               public indexOfPackage;
    mapping(bytes32 =>  uint256)            public TTL;
    mapping(uint256 =>  string)             public packageBelongsTo;
    mapping(address =>  packageDetails[])   public SubscribersList;
    mapping(string =>   bytes32)            public userCurrentNullifierHash;


    packageDetails[] private detailList;
    address SERVICE_PROVIDER_ADDRESS = 0x9e1611a42DA718FB14eCdE3fE6eba3Bb5B97F77B;


    uint TEST_PERIOD        =   5;
    uint TEST_SETUP_FEE     =   20;
    uint TEST_MINUTES_FEE   =   60;


    uint PERIOD      =  12;
    uint SETUP_FEE   =  2;
    uint MONTHLY_FEE =  3;


    uint LAST_PAID_INDEX        = 0;
    uint CURRENT_PACKAGE_INDEX  = 1;

    IVerifier   public immutable verifier;
    IPalo       public immutable fundsContract;

    // IProducts public immutable products;
    // IENS public immutable ensContract;
    // IServiceProviders public immutable serviceProvidersContract;


    struct packageDetails{
        uint packageStartingTime;
        bytes32 productIDHash;
        uint period;
    }

    event Commit(
        bytes32 indexed commitment,
        uint32 leafIndex,
        uint256 timestamp
    );

    event showInt(
        uint number
    );


    constructor(
        uint32      _levels,
        IHasher     _hasher,
        IVerifier   _verifier,
        IPalo       _fundsContract
    ) MerkleTreeWithHistory(_levels, _hasher) {
        verifier            = _verifier;
        fundsContract       = _fundsContract;
        packageBelongsTo[0] = "owner_of_contract_name"; // The connection between the user and the service provider index tracker
        indexOfPackage[0]   = 0;
        detailList.push(packageDetails(0,0,0));
    }

    // function _createSubscription(bytes32 _commitmentDeposit, bytes32 _productIDHash) internal {
    function _createSubscription(
        bytes32 _commitmentDeposit
    ) external {

        require(!commitments[_commitmentDeposit], "The commitment has been submitted");

        // uint setupFee = products.getSingleProduct(uint256(_productIDHash)).setupFee;
        // uint monthlyFee = products.getSingleProduct(uint256(_productIDHash)).monthlyFee;

        uint setupFee = 2;
        uint monthlyFee = 3;

        uint moneyToSend = monthlyFee * PERIOD + setupFee; // This will hard coded
        moneyToSend = monthlyFee * PERIOD; // Doesn't need to take the setup fee because he get the setup fee always.

        moneyToSend = TEST_MINUTES_FEE * TEST_PERIOD + TEST_SETUP_FEE; // 5 minutes TTL  + 20 setuo - 320      

        fundsContract.directTransferFContract(
            address(this),
            moneyToSend * 10 ** 18
        );

        commitments[_commitmentDeposit] = true;
        
        uint32 insertedIndex = _insert(_commitmentDeposit);
        emit Commit(_commitmentDeposit, insertedIndex, block.number);
    }

    // function _startSubscription(
    //     uint[2] memory _proof_a,
    //     uint[2][2] memory _proof_b,
    //     uint[2] memory _proof_c,
    //     bytes32 _nullifierHash,
    //     bytes32 _root,
    //     bytes32 _productIDHash,
    //     string memory ens
    // ) external {
    //     require(isKnownRoot(_root), "Cannot find your merkle root");
    //     require(
    //         verifier.verifyProof(
    //             _proof_a,
    //             _proof_b,
    //             _proof_c,
    //             [uint256(_nullifierHash), uint256(_root),uint256(_productIDHash)]
    //         ),
    //         "Invalid proof"
    //     );

    //     require(bytes32(indexOfPackage[_nullifierHash]) == 0, "package already activated"); // Because it already has an owner
    //     // uint fundsToProvider = 
    //     //     products.getSingleProduct(uint256(_productIDHash)).setupFee +
    //     //     products.getSingleProduct(uint256(_productIDHash)).monthlyFee;

    //     uint fundsToProviderForTheFirstMonth = SETUP_FEE + MONTHLY_FEE; // 2 + 3
    //     fundsToProviderForTheFirstMonth = MONTHLY_FEE; // Without setup fee... again the service provider holds it.


    //     fundsToProviderForTheFirstMonth = TEST_MINUTES_FEE; // for the first minute


    //     fundsContract.directTransfer(
    //         SERVICE_PROVIDER_ADDRESS,
    //         fundsToProviderForTheFirstMonth * 10 ** 18
    //     );

    //     uint startedPackageTime = block.timestamp + 30 days;

    //     startedPackageTime = block.timestamp + 1 minutes; // 60 seconds


    //     packageDetails memory details = packageDetails(startedPackageTime, _productIDHash, PERIOD - 1);
    //     detailList.push(details);

    //     packageBelongsTo[CURRENT_PACKAGE_INDEX] = ens; // The connection between the user and the service provider index tracker
    //     indexOfPackage[_nullifierHash] = CURRENT_PACKAGE_INDEX;

    //     userCurrentNullifierHash[ens] = _nullifierHash;

    //     CURRENT_PACKAGE_INDEX++;

    //     // // TTL[_nullifierHash] = 
    //     // //     block.timestamp + 
    //     // //         ((products.getSingleProduct(uint256(_productIDHash)).period - 1) * 30 days);

    //     // TTL[_nullifierHash] = block.timestamp + (PERIOD * 30 days); // That's the expiring date to keep track on the validation of the package
    //     TTL[_nullifierHash] = block.timestamp + TEST_PERIOD * 1 minutes; // going to expire in 5 minutes

    // }

    function calculateMonthsPast(
        uint packageStartingTime
    ) internal view returns(uint){

        uint secondsPast = (block.timestamp - packageStartingTime);

        // uint fullMonths = secondsPast / 30 days;
        // fullMonths = secondsPast;

        // // Check if there's any partial month to consider as a full month
        // if (secondsPast % 30 days > 0) {
        //     fullMonths++;
        // }

        // return fullMonths;

        if (secondsPast <= 0) {
            return 0;
        }
        return secondsPast;
    }

    function calculateMoneyToBePaid() public view returns(uint){

        uint totalFundsToTransfer = 0;

        for(uint i = LAST_PAID_INDEX; i < detailList.length; i++){
            
            // Takes one package details
            packageDetails memory singlePackageDetails = detailList[i]; 

            // checks how many more months left to be paid
            uint periodOfPackageLeft = singlePackageDetails.period;

            if (periodOfPackageLeft > 0){

                uint monthsToPay = calculateMonthsPast(singlePackageDetails.packageStartingTime);
                // uint monthlyFeeForPackage = products.getSingleProduct(uint256(singlePackageDetails.productIDHash)).monthlyFee;
                uint monthlyFeeForPackage = MONTHLY_FEE;

                if (monthsToPay > periodOfPackageLeft ) {
                    totalFundsToTransfer = periodOfPackageLeft * monthlyFeeForPackage;
                    totalFundsToTransfer = periodOfPackageLeft; // now for a seconds
                    // detailList[i].period = 0;
                    // LAST_PAID_INDEX = i;
                    // detailList[i].packageStartingTime = block.timestamp; // not relevant
                } else{
                    totalFundsToTransfer = monthsToPay * monthlyFeeForPackage;
                    totalFundsToTransfer = monthsToPay; // now for the seconds
                    // detailList[i].period -= monthsToPay; 
                    // detailList[i].packageStartingTime = block.timestamp + (30 days * monthsToPay);
                }
            }
        }

        // return (totalFundsToTransfer,LAST_PAID_INDEX);

        // emit showInt(totalFundsToTransfer);

        return totalFundsToTransfer;
    }

    function advancePaidIndex(uint _newIndex) external {
        LAST_PAID_INDEX = _newIndex;
    }

    // function _endSubscription( // Add Signature with nullifierHash
    //     uint[2] memory _proof_a,
    //     uint[2][2] memory _proof_b,
    //     uint[2] memory _proof_c,
    //     bytes32 _nullifierHash,
    //     bytes32 _root,
    //     bytes32 _productIDHash
    // ) external {
    //     require(!isPaid[_nullifierHash], "Already paid");
    //     require(isKnownRoot(_root), "Cannot find your merkle root");
    //     require(
    //         verifier.verifyProof(
    //             _proof_a,
    //             _proof_b,
    //             _proof_c,
    //             [uint256(_nullifierHash), uint256(_root),uint256(_productIDHash)]
    //         ),
    //         "Invalid proof"
    //     );


    //     int fundsToEntitlement = 0;
    //     uint fullMonths;
    //     int monthsToStillPayForProvider = 0; // starts with 0 because if the user didn't start the package then the user gets a full amount back - minus the setup fee... (that the service provider always gets)


    //     if(indexOfPackage[_nullifierHash] == 0){ // meaning the user didn't activate his subscription
    //         // fundsToEntitlement = 
    //         //     products.getSingleProduct(uint256(_productIDHash)).monthlyFee *
    //         //     products.getSingleProduct(uint256(_productIDHash)).period;
    //         // fullMonths = products.getSingleProduct(uint256(_productIDHash)).period;

    //         fullMonths = TEST_MINUTES_FEE * TEST_PERIOD;
    //         fundsToEntitlement = int(fullMonths);
    //     } 
    //     else{

    //         require(
    //             TTL[_nullifierHash] >= block.timestamp,
    //             "Package already expired"
    //         );

            
    //         uint secondsRemainingFromPackage = TTL[_nullifierHash] - block.timestamp;

    //         if (secondsRemainingFromPackage > ((TEST_MINUTES_FEE * TEST_PERIOD) - 1 minutes) ) { // that's the case that the user ended the package before the paid minute already... ( when we started) - 
    //             secondsRemainingFromPackage = ((TEST_MINUTES_FEE * TEST_PERIOD) - 1 minutes);             // equal for canceling in the first month - he already paid for it.
    //         }

    //         // // Need to check if that's below 1 month
    //         // // fullMonths = secondsPast / 30 days;
    //         // // fullMonths--;
    //         //                                                     // fundsToEntitlement = fullMonths * products.getSingleProduct(uint256(_productIDHash)).monthlyFee;
    //         // monthsToStillPayForProvider = PERIOD - fullMonths - 1; // -1 because he got already paid for the first month
            
    //         fundsToEntitlement = int(secondsRemainingFromPackage); // got paid for the first minute
    //         monthsToStillPayForProvider = (int(TEST_MINUTES_FEE * TEST_PERIOD) - fundsToEntitlement - 1 minutes);
    //         if (fundsToEntitlement < 0) {
    //             fundsToEntitlement = 0;
    //         }
    //         if (monthsToStillPayForProvider < 0){
    //             monthsToStillPayForProvider = 0;
    //         }
    //         emit showInt(uint(monthsToStillPayForProvider));

    //         detailList[indexOfPackage[_nullifierHash]].period = uint(monthsToStillPayForProvider); // can be 0 if the user didn't activate his package

    //     }

    //     // fundsToEntitlement = MONTHLY_FEE * fullMonths;
    //     emit showInt(uint(fundsToEntitlement));

    //     address USER_ADRESS = 0xe7660e821AD8F5ddc7FBB1c702C223cF934e2d23;
    //     fundsContract.directTransfer(
    //         USER_ADRESS,
    //        uint(fundsToEntitlement) * 10 ** 18
    //     );

    //     isPaid[_nullifierHash] = true;
    //     TTL[_nullifierHash] = block.timestamp;
    
    //     // // We update for the service provider to know that he he can get paid only for the months the user used until the cancelation.
    //     // // detailList[indexOfPackage[_nullifierHash]].period = 
    //     // //     products.getSingleProduct(uint256(_productIDHash)).period - fullMonths;
        
    // }


    function uintToString(
        uint v
    ) internal pure returns (string memory) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }

        return string(s);
    }

    function _getRemainingSubscriptionUserTime(
        string memory ens
    ) external view returns(int){

            bytes32 nullifierHash = userCurrentNullifierHash[ens];

            int TTLTime = int(TTL[nullifierHash]);
            int currentTime = int(block.timestamp);
            if(TTLTime - currentTime <= 0){
                return 0;
            }

            return TTLTime-currentTime;
    }

}