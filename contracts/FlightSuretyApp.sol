pragma solidity >=0.4.25;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";


/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)
    using SafeMath for uint; // Allow SafeMath functions to be called for all uint types (similar to "prototype" in Javascript)

    FlightSuretyData flightSuretyData;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    uint constant fee = 10 wei;  // would be ether in real life, but I don't have that much ether to work with
    mapping(address => bool) paidFee;

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    address payable private contractOwner;          // Account used to deploy contract

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
    }
    mapping(bytes32 => Flight) private flights;

    struct Insurance {
        bytes32 id;
        address passenger;
        bytes32 flight;
        uint amount;
        bool received;
    }
    mapping(bytes32 => Insurance) public insurances;
    mapping(address => uint256) private insuranceCredit;


    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational()
    {
         // Modify to call data contract's status
        require(flightSuretyData.isOperational(), "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /**
    * @dev Modifier that requires the sender to be a registered airline
    */
    modifier requireIsAirline()
    {
        require(flightSuretyData.isAirline(msg.sender), "Caller is not a registered airline");
        _;
    }

    /**
    * @dev Modifier that requires the sender to have paid a fee
    */
    modifier requireHasPaidFee()
    {
        require(paidFee[msg.sender], "Caller has not paid fee");
        _;
    }

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor
                                (
                                    address dataContractAddress
                                )
                                public
    {
        flightSuretyData = FlightSuretyData(dataContractAddress);
        contractOwner = msg.sender;
        paidFee[contractOwner] = true;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational()
                            public
                            view
                            returns(bool)
    {
        return flightSuretyData.isOperational();  // Modify to call data contract's status
    }

    function hasPaidFee()
                            public
                            view
                            returns(bool)
    {
        return paidFee[msg.sender];
    }

    /**
    * @dev Get voter for an airline's registration
    *
    * @return A bool that is the voter status of a queued airline
    */
    function getVoter(address airline)
                            public
                            view
                            returns(address payable[] memory)
    {
        return flightSuretyData.getVoters(airline);
    }

    function getFlightStatus(bytes32 flight)
        public
        view
        returns(uint)
    {
        return flights[flight].statusCode;
    }

    function getInsuranceAmount(bytes32 flight)
        public
        view
        returns(uint)
    {
        bytes32 id = keccak256(abi.encodePacked(msg.sender, flight));
        return insurances[id].amount;
    }

    function getInsuranceCredit()
        public
        view
        returns(uint)
    {
        return insuranceCredit[msg.sender];
    }

    function getInsuranceReceived(bytes32 flight)
        public
        view
        returns(bool)
    {
        bytes32 id = keccak256(abi.encodePacked(msg.sender, flight));
        return insurances[id].received;
    }




    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    function payFee()
        external
        requireIsAirline
        payable
        returns(bool)
    {
        // checks if value is enough ether
        require(msg.value >= fee, "Fee not enough.");
        // transfers ether
        contractOwner.transfer(fee);
        // refunds excess ether
        if (msg.value > fee)
        {
            msg.sender.transfer(msg.value.sub(fee));
        }
        // sets paidFee to true
        paidFee[msg.sender] = true;
        return paidFee[msg.sender];
    }


    /**
     * @dev Add an airline to the registration queue
     *      Can only be called from FlightSuretyApp contract
     *
     */
     function addAirline
                             (
                                 address newAirline
                             )
                             external
                             requireIsAirline
                             requireHasPaidFee
                             returns(bool)
     {
         // executes if there are less than four airlines
         if (flightSuretyData.getAirlineCount() < flightSuretyData.getM())
         {
             // executes if airline has not yet been queued
             if (!flightSuretyData.isAirline(newAirline) && !flightSuretyData.isQueued(newAirline))
             {
                 // queues airline
                 flightSuretyData.queueAirline(newAirline, msg.sender);
                 // registers airline
                 return flightSuretyData.registerAirline(newAirline, msg.sender);
             }
             // registers airline if it is on queue
             else if (flightSuretyData.isQueued(newAirline))
             {
                 // registers airline
                 return flightSuretyData.registerAirline(newAirline, msg.sender);
             }
         }
         else {
             // executes if airline has not yet been queued
             if (!flightSuretyData.isAirline(newAirline) && !flightSuretyData.isQueued(newAirline))
             {
                 // queues airline
                 return flightSuretyData.queueAirline(newAirline, msg.sender);
             }
             // votes for airline if it is on queue
             else if (flightSuretyData.isQueued(newAirline))
             {
                 //require(flightSuretyData.getVoter(newAirline) == false, "Caller has already voted");

                 // count votesForRegistration
                 uint num = flightSuretyData.getVotesForRegistration(newAirline);
                 // vote for airline
                 uint num2 = flightSuretyData.voteForRegistration(newAirline, msg.sender);
                 // check if new votes got through
                 if ((num.add(1)) == num2)
                 {
                     if (num2 >= (flightSuretyData.getAirlineCount().div(2)))
                     {
                         return flightSuretyData.registerAirline(newAirline, msg.sender);
                     }
                 }
                 else {
                     revert("Vote did not go through");
                 }
             }
         }
     }


   /**
    * @dev Register a future flight for insuring.
    *
    */
    function registerFlight
                                (
                                    address airline,
                                    string calldata flight,
                                    uint256 timestamp,
                                    uint8 statusCode
                                )
                                external
                                payable
    {
        bytes32 key = getFlightKey(airline, flight, timestamp);
        flights[key].isRegistered = true;
        flights[key].statusCode = statusCode;
        flights[key].updatedTimestamp = timestamp;
        flights[key].airline = airline;
    }


    function purchaseInsurance(
        bytes32 flight,
        uint amount
    )
        public
        payable
        returns(bytes32)
    {
        require(amount <= 1 ether, "Amount too much.");
        require(msg.value >= amount, "Amount not enough.");

        contractOwner.transfer(amount);
        bytes32 id = keccak256(abi.encodePacked(msg.sender, flight));
        insurances[id].id = id;
        insurances[id].passenger = msg.sender;
        insurances[id].flight = flight;
        insurances[id].amount = amount;
        insurances[id].received = false;

        return id;
    }


    function receiveInsurancePayment(
        bytes32 flight
    )
        public
        payable
    {
        // correct reason for insurance
        require(flights[flight].statusCode == STATUS_CODE_LATE_AIRLINE, "Flight not available for insurance payment");

        // find insurance
        bytes32 id = keccak256(abi.encodePacked(msg.sender, flight));
        uint amount = insurances[id].amount;

        // make sure insurance has not yet been received
        require(!insurances[id].received, "Insurance already received");
        insurances[id].received = true;

        // pay
        insuranceCredit[msg.sender] = amount.mul(3).div(2);
    }


    function withdrawInsurancePayment(uint amount)
        public
        payable
    {
        // amount has to be enough
        require(insuranceCredit[msg.sender] >= amount, "Amount not enough");

        // withdraw requested amount
        insuranceCredit[msg.sender] = insuranceCredit[msg.sender].sub(amount);

        // pay
        msg.sender.transfer(amount);
    }

    function changeFlightStatus(bytes32 flight, uint8 statusCode)
        requireContractOwner
        public
    {
        flights[flight].statusCode = statusCode;
    }

   /**
    * @dev Called after oracle has updated flight status
    *
    */
    function processFlightStatus
                                (
                                    address airline,
                                    string memory flight,
                                    uint256 timestamp,
                                    uint8 statusCode
                                )
                                internal
                                pure
    {

    }


    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus
                        (
                            address airline,
                            string calldata flight,
                            uint256 timestamp
                        )
                        external
    {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({
                                                requester: msg.sender,
                                                isOpen: true
                                            });

        emit OracleRequest(index, airline, flight, timestamp);
    }


// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);


    // Register an oracle with the contract
    function registerOracle
                            (
                            )
                            external
                            payable
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes
                            (
                            )
                            view
                            external
                            returns(uint8[3] memory)
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            address airline,
                            string calldata flight,
                            uint256 timestamp,
                            uint8 statusCode
                        )
                        external
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }


    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        public
                        returns(bytes32)
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (
                                address account
                            )
                            internal
                            returns(uint8[3] memory)
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);

        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

}



contract FlightSuretyData {
    function isOperational() public view returns(bool);
    function isAirline(address airlineAddress) public view returns(bool);
    function isQueued(address airlineAddress) public view returns(bool);
    function getAirlineCount() public view returns(uint);
    function getM() public view returns(uint);
    function getVotesForRegistration(address airline) public view returns(uint);
    function getVoters(address airline) public view returns(address payable[] memory);
    function queueAirline(address newAirline, address senderAirline) external returns(bool);
    function voteForRegistration(address newAirline, address senderAirline) external returns(uint);
    function registerAirline(address newAirline, address senderAirline) external returns(bool);
}
