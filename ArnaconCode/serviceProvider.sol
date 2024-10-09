// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./products.sol";
import "./interfaces.sol";

struct timeNCool {
        uint packageTime;
        uint cooldownTime;
}

contract serviceProvider { 

    // New contracts that will be deployed for every service provider
    Products              productsContract;

    // Existing contract that upon creation- need to be specified
    IMetadata           MetadataContract;
    IServiceProviders   SPSContracts;
    IENS                EnsContract;
    IAyala              ayalaContract;

    address public OWNER;

    // Mapping to store admins (key: address, value: bool)
    mapping(address => bool) public admins;

    // Event to notify when an admin is added or removed
    event AdminChanged(address indexed admin, bool isAdded);

    event showENS(string ens);


    mapping(string =>   address)    public GSM;
    mapping(string =>   address)    public EMAIL;

    mapping(uint =>     string)     public KamailioIPSCall;
    mapping(string =>   uint)       public GSMIPSCall;

    mapping(string =>   uint256)    public TTL;
    mapping(string =>   uint256)    public COOLDOWN;

    mapping(uint =>     string)     public KamailioIPSMessage;
    mapping(string =>   uint)       public GSMIPSMessage;   

    mapping(bytes32 =>  string)     private PublicKey;


    uint    public INDEX_OF_METADATA;
    bytes32 public SERVICE_PROVIDER_NODE;
    string  public SERVICE_PROVIDER_DOMAIN;

    uint256 public indexOfIPCall    = 1; 
    uint256 public indexOfIPMessage = 1; 


    event showAddress(
        address subscriptionContract
    );

    event showDetails(
        address subscriptionContract
    );

    modifier onlyOwner() {
        require(msg.sender == OWNER, "You are not the owner.");
        _;
    }
    
    constructor(
        IMetadata           _metadataContract,
        IServiceProviders   _spsContract,
        IAyala              _ayalaContract,
        bytes32             _serviceProviderNode, // ENS Namehash
        string memory       _metaData,
        string memory       _serviceProviderDomain
    ) payable {
        
        OWNER = msg.sender;
        admins[OWNER] = true; // Owner is also an admin

        _spsContract.safeMint{
            value: msg.value / 2
        }(
            _serviceProviderNode,
            msg.sender
        );

        INDEX_OF_METADATA = _metadataContract.safeMint{
            value: msg.value / 2
        }(
            msg.sender,
            _metaData
        ); 

        SERVICE_PROVIDER_NODE =  _serviceProviderNode;
        SERVICE_PROVIDER_DOMAIN = _serviceProviderDomain;
        SPSContracts         =  _spsContract;
        MetadataContract     =  _metadataContract;
        ayalaContract        =  _ayalaContract;

        productsContract     =  new Products        (
                                                        _metadataContract
                                                    );
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "You must be an admin to perform this action.");
        _;
    }

    function addAdmin(address _admin) public onlyOwner {
        require(_admin != address(0), "Invalid admin address.");
        require(!admins[_admin], "Admin already exists.");

        admins[_admin] = true;
        emit AdminChanged(_admin, true);
    }

    // Function to remove an admin
    function removeAdmin(address _admin) public onlyOwner {

        require(admins[_admin], "Admin does not exist.");

        admins[_admin] = false;

        emit AdminChanged(_admin, false);
    }

    function getServiceProviderMetadata(
    ) public view returns(string memory) {

        return MetadataContract.tokenURI (
                                            INDEX_OF_METADATA
                                         );
    }   

    function getServiceProviderDomain() external view returns(string memory){
        return SERVICE_PROVIDER_DOMAIN;
    }

    function addProduct(
        uint _setupFee, 
        uint _monthlyFee, 
        string memory _metaData
    ) public payable{

        productsContract._addProduct(
                                        _setupFee,
                                        _monthlyFee,
                                        _metaData,
                                        msg.sender
                                    );
    }

    // ENS- fixed 365 days.
    function updateNewServiceProvider(
        bytes   memory _signature, 
        string  memory _messageSigned, 
        bytes32        _ENSNode // ENS
    ) external {

        ayalaContract.updateUserRegistery ( 
                                                _signature, 
                                                _messageSigned, 
                                                _ENSNode
                                            );

        TTL[bytes32ToString(_ENSNode)] = block.timestamp + 365 days;
    
    }


    function getProductMetaData(
        uint256 _productID
    ) public  view returns(string memory){

        return productsContract._getProductMetaData(_productID);
    }


    // Adding new IP to routing for calling
    function addNewIPRouteCall(
        string memory ip
    ) external onlyAdmin {

        KamailioIPSCall[indexOfIPCall] = ip;
        indexOfIPCall *= 2;
        // Doubling index to maintain uniqueness and power of two
        // a. 1 b. 2 c. 4 d. 8 e. 16.       25 -> e + d + a

    }

    // Adding new IP to routing for messaging
    function addNewIPRouteMessage(
        string memory ip
    ) external onlyAdmin {

        KamailioIPSMessage[indexOfIPMessage] = ip;
        indexOfIPMessage *= 2;

    }

    // function that returns all the ips for a certain gsm number for calling
    function getIPsForNumberCall(
        uint256 number
    ) public view returns (string[] memory) {

        require(number <= indexOfIPCall, "Out of bound");

        uint256 temp = number;
        uint256 bitIndex = 0;
        uint256 count = 0;

        // First, determine how many IPs we need to return
        while (temp > 0) {
            if (temp % 2 == 1) {
                count++;
            }
            temp = temp >> 1;
            bitIndex++;
        }

        // Create an array to hold the IPs
        string[] memory ips = new string[](count);

        // Reset for actual extraction
        temp = number;
        bitIndex = 0;
        uint256 arrayIndex = 0;

        // Extract IPs corresponding to set bits
        while (temp > 0) {
            if (temp % 2 == 1) {
                // Retrieve IP if it exists for the power of two position
                if (keccak256(abi.encodePacked(KamailioIPSCall[2**bitIndex])) != keccak256(abi.encodePacked(""))) {
                    ips[arrayIndex] = KamailioIPSCall[2**bitIndex];
                    arrayIndex++;
                }
            }
            temp = temp >> 1;
            bitIndex++;
        }

        return ips;
    }

    // function that returns all the ips for a certain gsm number for messaging
    function getIPsForNumberMessage(
        uint256 number
    ) public view returns (string[] memory) {

        require(number <= indexOfIPMessage, "Out of bound");

        uint256 temp = number;
        uint256 bitIndex = 0;
        uint256 count = 0;

        // First, determine how many IPs we need to return
        while (temp > 0) {
            if (temp % 2 == 1) {
                count++;
            }
            temp = temp >> 1;
            bitIndex++;
        }

        // Create an array to hold the IPs
        string[] memory ips = new string[](count);

        // Reset for actual extraction
        temp = number;
        bitIndex = 0;
        uint256 arrayIndex = 0;

        // Extract IPs corresponding to set bits
        while (temp > 0) {
            if (temp % 2 == 1) {
                // Retrieve IP if it exists for the power of two position
                if (keccak256(abi.encodePacked(KamailioIPSMessage[2**bitIndex])) != keccak256(abi.encodePacked(""))) {
                    ips[arrayIndex] = KamailioIPSMessage[2**bitIndex];
                    arrayIndex++;
                }
            }
            temp = temp >> 1;
            bitIndex++;
        }

        return ips;
    }

    // the conductors for the last function to get the ips
    function getIPSFromNumberCall(string memory gsm_number) public view returns (string[]memory) {
        return getIPsForNumberCall(GSMIPSCall[gsm_number]);
    }

    function getIPSFromNumberMessage(string memory gsm_number) public view returns (string[]memory) {
        return getIPsForNumberMessage(GSMIPSMessage[gsm_number]);
    }

    mapping(string => timeNCool) private productCoolNTime;

    // adding a new gsm number to your database + metadata contract about the number
    function addGSM(
        string memory gsm_number, 
        string memory gsm_metadata, 
        uint256 time_of_package_in_seconds, // 30-365 days package
        uint cooldown_time_of_package_in_seconds, // How long the number cannot be allocated to a new customer
        uint IPSForNumberCall, 
        uint IPSForNumberMessage
    ) external onlyAdmin {

        require(GSMIPSCall[gsm_number] == 0, "GSM number already exists");

        MetadataContract.safeMint(
            msg.sender,
            gsm_metadata
        );

        productCoolNTime[gsm_number] = timeNCool(time_of_package_in_seconds, cooldown_time_of_package_in_seconds);

        GSMIPSCall[gsm_number] = IPSForNumberCall;

        GSMIPSMessage[gsm_number] = IPSForNumberMessage;

    }

    function updateIPSForNumber(
        string memory gsm_number, 
        uint IPSForNumberCall, 
        uint IPSForNumberMessage
    ) external onlyAdmin {

        require(GSMIPSCall[gsm_number] != 0, "First add the GSM.");

        GSMIPSCall[gsm_number] = IPSForNumberCall;
        GSMIPSMessage[gsm_number] = IPSForNumberMessage;
    }

    // assign the gsm number to a customer!
    function listGSM(
        string memory gsm_number,
        address user_address
    ) external onlyAdmin {

        if (GSM[gsm_number] != user_address){
            require(COOLDOWN[gsm_number] <= block.timestamp, "Cooldown time need to pass in order to ");
        } 
        
        GSM[gsm_number] = user_address;

        TTL[gsm_number] = block.timestamp + productCoolNTime[gsm_number].packageTime;

        COOLDOWN[gsm_number] = TTL[gsm_number] + productCoolNTime[gsm_number].cooldownTime;
        
    }

    // MAIL
    function updateEmailServiceProvider(
        bytes   memory _signature, 
        string  memory _commitment, 
        bytes32        _ENSNode // Email node
    ) external{

            return ayalaContract.updateUserRegistryWithCommitmentCheck ( 
                                                        _signature, 
                                                        _commitment, 
                                                        _ENSNode
                                                    );
    }

    // namehash or not?
    function listEmail(
        string memory email,
        address user_address
    ) external onlyAdmin {
        EMAIL[email] = user_address; 
    }



    // returns if the user is valid
    function isUserValid(
        string memory product
    ) external view returns(bool){

        return TTL[product] >= block.timestamp;

    }


    // NFT?
    function updatePublicKeyForProduct(
        bytes32 _ENSNode,
        string memory publicKeyBase64Format
    ) external {
        PublicKey[_ENSNode] = publicKeyBase64Format;
    }

    function getUserPublicKey(
        bytes32 _ENSNode
    )external view returns(string memory) {
        return PublicKey[_ENSNode];
    }







    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

     // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}





    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        // We need to create a bytes array first with the correct length
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }

        // Create a new bytes array with the length of the string
        bytes memory bytesArray = new bytes(i);

        // Copy data from bytes32 to the new bytes array
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }

        // Convert bytes array to string and return
        return string(bytesArray);
    }

}

//Private blockchain
// 20, 0x1BdA40cc2F4967F594238b837C6adA89962C5B88, 0x7b052B26fB5d8C15687AF2B93CE47cE3e2600D98, 0x5c5348FbA2928D99fd8f8314185C1940Da9bE620, 0x8fe9dFe0C3B69E9676431F5367740C677759899d, 0x9C7eDaB386fCc99b00B633B2C730C731ECAf873A, 0x275d34dAa8708F9e74e7b452DE7DE9029dCeb7F7, kaksjdlaskdxc, k21n3lmsdlsd

// Amoy
// 0xBbc0Df4318e994987Fc12E57fA8Ff697171D684A, 0x993f1a78B3B7438bf080B0D21ffD5Ae492a4FA3d, 0xADD3F1c90591c7B2364E2fA35F5839000641eacB

// start - 0x9e1611a42DA718FB14eCdE3fE6eba3Bb5B97F77B ( service Provider)

// IPS - 185.62.121.10

// test1.cellact node - 0x3f31eef2af3f6e2b70b6423edce33be3d9b0de2dbd3cb2489179eded133d76b3
// test2.cellact node - 0x0946253d45e8680112e58f232c070e4cf4a9c318f5bce7bdcb3f28c309b3e908
// paris1.cellact.nl -  0xeeeb2eacbd1a460ad83e4f0a99e8907b0a54ba2ece83e553850fc72aeecc9961