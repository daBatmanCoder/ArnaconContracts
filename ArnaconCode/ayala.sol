// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./merkleTree.sol";
import "./interfaces.sol";
import "./ENSNameHash.sol";

contract Ayala {

    // mapping(bytes32 =>  bool)       public  nullifiersAyala;
    // mapping(bytes32 =>  bool)       public  commitmentsAyala;


    mapping(bytes   =>      bool)      private signautres;
    mapping(bytes32 =>      address)   private AyalA;
    mapping(string  =>      address)   private commitments;
    mapping(string  =>      bool)      private commitmentsUsed;

    address OWNER;

    IENS                public immutable ens;
    IDorot              public immutable dorot;

    event Commit(
        bytes32 indexed commitment,
        uint32 leafIndex,
        uint256 timestamp
    );


    modifier onlyOwner() {
        require(msg.sender == OWNER, "You are not the owner.");
        _;
    }

    event showBytes(bytes data);
    event showSignature(uint8 v, bytes32 r, bytes32 s);
    event showString(string data);
    event showAddress(address data);
    event showBool(bool data); 

    constructor(
        IENS            _ens,
        IDorot          _dorot 
    ) {
        ens = _ens;
        dorot = _dorot;
        OWNER = msg.sender;
    }

    function updateUser(bytes32 _node) external onlyOwner {
        AyalA[_node] =  msg.sender; // Is the one the user gave that signature to
    }

    function updateUserWAddress(bytes32 _node, address _address) external onlyOwner{
        AyalA[_node] =  _address; // Is the one the user gave that signature to
    }

    function commitmentForChange(string memory _commitment, address userAddress) external onlyOwner{
        require(!commitmentsUsed[_commitment], "commitment is already being used to change the registry");
        commitments[_commitment] = userAddress;
        // commitmentsUsed[_commitment] = true; Think about that
    }

    // cus_QSD9A8LkQKZcIt
    // 0xd50eb212Ea834481bEDD5ac5d0A737B188fad0dE

    // 0x38876e28b802ce06d5dc406dfdcac83f6f21a922d2e8e09a2e2cfb8c55184a494b178c204fadb8f3aab45f85a778b6b7450341b9dcfadf5d8370a53b5364cbca1b
    // 0x006488d12224ee76ae61eb7c6bd8a36c5827d5b1cd3d3623c7402d01c72bef56 - 

    
    function updateUserRegistryWithCommitmentCheck(
        bytes       memory  _signature, 
        string      memory  _commitment,
        bytes32             _node // namehash of ENS
     ) external {
        require(!commitmentsUsed[_commitment], "commitment is already being used to change the registry");
        // encode the signature to be bytes

        require(
            !signautres[_signature],
            "Signature already used"
        );

        address userAddress = commitments[_commitment];

        require(
            verifySignature(userAddress,_commitment, _signature),
            "The user didn't give you the permission to change his registry"
        );

        AyalA[_node] =  msg.sender; // Is the one the user gave that signature to

        signautres[_signature] = true;
        commitmentsUsed[_commitment] = true;
    }

    function updateUserRegistery(
        bytes   memory _signature, 
        string  memory _messageSigned, 
        bytes32        _node // namehash of ENS
    ) external {

        require(
            !signautres[_signature],
            "Signature already used"
        );

        address userAddress = ens.owner(_node); 
 
        require(
            verifySignature(userAddress,_messageSigned, _signature),
            "The user didn't give you the permission to change his registry"
        );

        AyalA[_node] =  msg.sender; // Is the one the user gave that signature to
        signautres[_signature] = true;


        // New Ayala versions
        dorot.ayalaVersion(_signature, _messageSigned, _node, address(this));

    }

    function getENSToServiceProvider(
        bytes32 _node
    ) public view returns (address){

        return AyalA[_node];
    }

    function extractUserAddress(
        string memory message, 
        bytes memory signature
    ) internal pure returns(address){

        bytes32 hashedMessage = computeHash(message);
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
        return ecrecover(hashedMessage, v, r, s);
    }
    
    function verifySignature(address user, string memory message, bytes memory signature)
        public
        pure
        returns (bool)
    {   
        return extractUserAddress(message, signature) == user;
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

    function bytes32ToBytes(bytes32 data) public pure returns (bytes memory) {
        bytes memory result = new bytes(32);
        assembly {
            mstore(add(result, 32), data)
        }
        return result;
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


// 20, 0x3542Cbdd6c0948A0f4f82F2a1ECb33FA4f55f242, 0xFc0dd5bD2e980ae3b4E51E39ce74667fc97ED28e, 0x1BdA40cc2F4967F594238b837C6adA89962C5B88


// ["0x2d54249889e15a161a285774810f004e133ee11a250e1a8391527f46275d0f6f", "0x2f5967a0e01680c42f40127fd50c5ccf865177164a5dcee7a3fc8c3d6589f094"],[["0x0bff60f5de5191c6d10a90d3bb4fa0af25603f722dc8e6f8ff4d82831d005721", "0x2b99bde6dcc3bbc134d73067981e393f930fcaf62a5dbe5931acb75b1f258769"],["0x27bf2c66168385b02dc5ba21718992a61d30f758e9469cbbfb0cfd004a5a8cdb", "0x11dabc5d0fd8fbe024b20bc29fef8b9ff559dbe6b991e75512212c7888762bf8"]],["0x1a00c33bb9775999672b3eaf66baa30062effedcc61429ca2d16547b0bd0afec", "0x2c3a63680ff3754c2e37817a5c4e2e92c4f2fbfbb089a409b9c9fef9061c102b"],["0x1a966822dd4de92c9ceb042e772b0bde97004b6c381f181cf41ae52d6bef5a8e","0x0c4386cb71dbf3909a8d99436d39b128bcd9ddf4ec44d0c8249e8930911a172a"]