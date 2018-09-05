pragma solidity ^0.4.18;
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

contract ShareDiceGame is usingOraclize {
    address public owner;//合约所有者

    modifier isOwner() {
        require(msg.sender==owner, "msg sender is not owner");
        _;
    }

    constructor() public {
        owner=msg.sender;
        oraclize_setProof(proofType_Ledger);//sets the Ledger authenticity proof in the constructor
    }

    event newRandomNumber_uint(uint);

    function __callback(bytes32 _queryId, string _result, bytes _proof) { 
        if (msg.sender != oraclize_cbAddress()) throw;
        if (oraclize_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0) {
            // the proof verification has failed, do we need to take any action here? (depends on the use case)
        } else {
            uint maxRange = 2**(8* 7); // this is the highest uint we want to get. It should never be greater than 2^(8*N), where N is the number of random bytes we had asked the datasource to return
            uint randomNumber = uint(sha3(_result)) % maxRange; // this is an efficient way to get the uint out in the [0, maxRange] range
            newRandomNumber_uint(randomNumber); // this is the resulting random number (uint)

        }
    }

    function updateRandomNum() payable {
        uint N = 7; // number of random bytes we want the datasource to return
        uint delay = 0; // number of seconds to wait before the execution takes place
        uint callbackGas = 200000; // amount of gas we want Oraclize to set for the callback function
        bytes32 queryId = oraclize_newRandomDSQuery(delay, N, callbackGas); // this function internally generates the correct oraclize_query and returns its queryId

    }
}

