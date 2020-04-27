pragma solidity >=0.4.25;

import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

    struct AirlineProfile {
        bool isQueued;
        uint votesForRegistration;
        address[] voters;
        bool isRegistered;
    }

    uint constant M = 4;
    uint public airlineCount;
    address[] multiCalls = new address[](0);
    mapping(address => AirlineProfile) airlineProfiles;   // Mapping for storing airline profiles

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                )
                                public
    {
        airlineProfiles[msg.sender].isQueued = false;
        airlineProfiles[msg.sender].votesForRegistration = 0;
        airlineProfiles[msg.sender].voters.push(msg.sender);
        airlineProfiles[msg.sender].isRegistered = true;
        airlineCount = 1;
        contractOwner = msg.sender;
    }

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
        require(operational, "Contract is currently not operational");
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
        require(isAirline(msg.sender), "Caller is not a registered airline");
        _;
    }


    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */
    function isOperational()
                            public
                            view
                            returns(bool)
    {
        return operational;
    }

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */
    function isAirline(
        address airlineAddress
    )
                            public
                            view
                            returns(bool)
    {
        return airlineProfiles[airlineAddress].isRegistered;
    }

    /**
    * @dev Get queued status of airline
    *
    * @return A bool that is the current airline queued status
    */
    function isQueued(
        address airlineAddress
    )
                            public
                            view
                            returns(bool)
    {
        return airlineProfiles[airlineAddress].isQueued;
    }


    /**
    * @dev Get numbered of airlines
    *
    * @return A uint that is the current number of airlines
    */
    function getAirlineCount()
                            public
                            view
                            returns(uint)
    {
        return airlineCount;
    }


    /**
    * @dev Get minimum numbered of airlines
    *
    * @return A uint that is the minimum number of airlines
    */
    function getM()
                            public
                            view
                            returns(uint)
    {
        return M;
    }


    /**
    * @dev Get votes for an airline's registration
    *
    * @return A uint that is the number of votes for registration an airline acquires
    */
    function getVotesForRegistration(address airline)
                            public
                            view
                            returns(uint)
    {
        return airlineProfiles[airline].voters.length;
    }

    /**
    * @dev Get voter for an airline's registration
    *
    * @return A bool that is the voter status of a queued airline
    */
    function getVoters(address airline)
                            public
                            view
                            returns(address[] memory)
    {
        return airlineProfiles[airline].voters;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */
    function setOperatingStatus
                            (
                                bool mode
                            )
                            external
                            requireContractOwner
    {
        require(mode != operational, "New mode must be different from existing mode");
        require(airlineProfiles[msg.sender].isRegistered, "Caller is not registered");

        bool isDuplicate = false;
        for(uint c=0; c<multiCalls.length; c++) {
            if (multiCalls[c] == msg.sender) {
                isDuplicate = true;
                break;
            }
        }
        require(!isDuplicate, "Caller has already called this function.");

        multiCalls.push(msg.sender);
        if (multiCalls.length >= M) {
            operational = mode;
            multiCalls = new address[](0);
        }
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */
    function queueAirline
                            (
                                address newAirline,
                                address senderAirline
                            )
                            external
                            returns(bool)
    {
        // add airline to mapping
        airlineProfiles[newAirline].isQueued = true;
        airlineProfiles[newAirline].votesForRegistration += 1;
        airlineProfiles[newAirline].voters.push(senderAirline);
        airlineProfiles[newAirline].isRegistered = false;

        return bool(airlineProfiles[newAirline].isQueued);
    }


    /**
     * @dev Vote for an airline to be added to the registration queue
     *      Can only be called from FlightSuretyApp contract
     *
     */
     function voteForRegistration
                             (
                                 address newAirline,
                                 address senderAirline
                             )
                             external
                             //requireContractOwner
                             returns(uint)
     {
         bool isDuplicate;
         for(uint c=0; c < airlineProfiles[newAirline].voters.length; c++) {
             if (airlineProfiles[newAirline].voters[c] == senderAirline) {
                 isDuplicate = true;
                 break;
             }
         }

         if (!isDuplicate)
         {
             // add vote
             airlineProfiles[newAirline].voters.push(senderAirline);
             airlineProfiles[newAirline].votesForRegistration += 1;
             return airlineProfiles[newAirline].votesForRegistration;
         }
         else {
             revert("Airline already voted");
         }
     }


    /**
     * @dev Register an airline
     *      Can only be called from FlightSuretyApp contract
     *
     */
     function registerAirline
                             (
                                 address newAirline,
                                 address senderAirline
                             )
                             external
                             returns(bool)
     {
         // add airline to mapping
         airlineProfiles[newAirline].isQueued = false;
         airlineProfiles[newAirline].isRegistered = true;
         // add to airlineCount
         airlineCount += 1;
         // return
         return bool(airlineProfiles[newAirline].isRegistered);
     }


   /**
    * @dev Buy insurance for a flight
    *
    */
    function buy
                            (
                            )
                            external
                            payable
    {

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                pure
    {
    }


    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            pure
    {
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */
    function fund
                            (
                            )
                            public
                            payable
    {
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32)
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function()
                            external
                            payable
    {
        fund();
    }


}
