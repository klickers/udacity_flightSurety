var FlightSuretyData = artifacts.require("FlightSuretyData");
var FlightSuretyApp = artifacts.require("FlightSuretyApp");

var BigNumber = require('bignumber.js');
//var stuff = require('./stuff.js')


contract('Flight Surety Tests', async (accounts) => {

    var owner;
    var airline1;
    var airline2;
    var airline3;
    var airline4;
    var airline5;
    var flightSuretyData;
    var flightSuretyApp;
    const STATUS_CODE_UNKNOWN = 0;
    const STATUS_CODE_ON_TIME = 10;
    const STATUS_CODE_LATE_AIRLINE = 20;
    const STATUS_CODE_LATE_WEATHER = 30;
    const STATUS_CODE_LATE_TECHNICAL = 40;
    const STATUS_CODE_LATE_OTHER = 50;
    const timestamp = Date.now();
    before('setup contract', async () => {
        owner = accounts[0];
        airline1 = accounts[1];
        airline2 = accounts[2];
        airline3 = accounts[3];
        airline4 = accounts[4];
        airline5 = accounts[5];
        console.log(owner, "owner")
        console.log(airline1, "airline1")
        console.log(airline2, "airline2")
        console.log(airline3, "airline3")
        console.log(airline4, "airline4")
        console.log(airline5, "airline5")
        flightSuretyData = await FlightSuretyData.new( { from: owner } );
        console.log(flightSuretyData.address, "address")
        flightSuretyApp = await FlightSuretyApp.new(flightSuretyData.address, { from: owner });
    });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try
      {
          await flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");

  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try
      {
          await flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");

  });

  it('owner is registered (airline)', async () => {

    // ARRANGE
    let isAirline = false;

    // ACT
    try {
        isAirline = await flightSuretyData.isAirline(owner);
    }
    catch(e) {
        console.error(e)
    }

    // ASSERT
    assert.equal(isAirline, true, "Contract owner should be a registered airline");

  });


  it('registered (airline) can register an airline2', async () => {

    // ARRANGE
    let newAirline = airline2;

    // ACT
    try {
        await flightSuretyApp.addAirline(newAirline, {from: owner});
    }
    catch(e) {
        console.error(e)
    }
    let result = await flightSuretyData.isAirline.call(newAirline);

    // ASSERT
    assert.equal(result, true, "Airline should be able to register airline2");

  });


  it('registered (airline)2 needs to pay fee', async () => {

    // ARRANGE
    let newAirline = airline2;
    // would be ether in real life, but wei as I'm testing.
    // the fee is 10 wei; the 12 wei tests the refund function works
    let ether = web3.utils.toWei("12", 'wei');

    // ACT
    try {
        await flightSuretyApp.payFee({from: airline2, value: ether });
    }
    catch(e) {
        console.error(e)
    }
    let result = await flightSuretyApp.hasPaidFee.call();


    // ASSERT
    assert.equal(result, true, "Airline should be able to pay fee");

  });


  it('registered (airline) 2 can register an airline 3', async () => {

    // ARRANGE
    let newAirline = airline3;

    // ACT
    try {
        await flightSuretyApp.addAirline(newAirline, {from: airline2});
    }
    catch(e) {
        console.error(e)
    }
    let result = await flightSuretyData.isAirline.call(newAirline);

    // ASSERT
    assert.equal(result, true, "Airline2 should be able to register airline3");

  });

  it('registered (airline)3 needs to pay fee', async () => {

    // ARRANGE
    let newAirline = airline3;
    let ether = web3.utils.toWei("10", 'wei'); // would be ether in real life, but wei as I'm testing

    // ACT
    try {
        await flightSuretyApp.payFee({from: airline3, value: ether });
    }
    catch(e) {
        console.error(e)
    }
    let result = await flightSuretyApp.hasPaidFee.call();

    // ASSERT
    assert.equal(result, true, "Airline should be able to pay fee");

  });

  it('registered (airline) 3 can register an airline 4', async () => {

    // ARRANGE
    let newAirline = airline4;

    // ACT
    try {
        await flightSuretyApp.addAirline(newAirline, {from: airline3});
    }
    catch(e) {
        console.error(e)
    }
    let result = await flightSuretyData.isAirline.call(newAirline);

    // ASSERT
    assert.equal(result, true, "Airline3 should be able to register airline4");

  });

  it('registered (airline)4 needs to pay fee', async () => {

    // ARRANGE
    let newAirline = airline4;
    let ether = web3.utils.toWei("10", 'wei'); // would be ether in real life, but wei as I'm testing

    // ACT
    try {
        await flightSuretyApp.payFee({from: airline4, value: ether });
    }
    catch(e) {
        console.error(e)
    }
    let result = await flightSuretyApp.hasPaidFee.call();

    // ASSERT
    assert.equal(result, true, "Airline should be able to pay fee");

  });

  it('registered (airline) 4 cannot register but can queue an airline 5', async () => {

    // ARRANGE
    let newAirline = airline5;
    let result;

    // ACT
    try {
        await flightSuretyApp.addAirline(newAirline, {from: airline4});
    }
    catch(e) {
        console.error(e)
    }
    result = await flightSuretyData.isQueued.call(newAirline);
    votes = await flightSuretyData.getVotesForRegistration.call(newAirline)

    // ASSERT
    assert.equal(result, true, "Airline should not be able to register, but can queue airline5")
    assert.equal(votes, 1, "Airline should have a vote of 1")
  });

  it('registered (airline) 3 can register an airline 5', async () => {

    // ARRANGE
    let newAirline = airline5;
    let result;

    // ACT
    try {
        await flightSuretyApp.addAirline(newAirline, {from: airline3});
    }
    catch(e) {
        console.error(e)
    }
    result = await flightSuretyData.isAirline.call(newAirline);
    votes = await flightSuretyData.getVotesForRegistration.call(newAirline)

    // ASSERT
    assert.equal(result, 1, "Airline should be able to register airline5");
    assert.equal(votes, 2, "Airline should have a vote of 2")
  });

  it('registered (airline)5 needs to pay fee', async () => {

    // ARRANGE
    let newAirline = airline5;
    let ether = web3.utils.toWei("10", 'wei'); // would be ether in real life, but wei as I'm testing

    // ACT
    try {
        await flightSuretyApp.payFee({from: airline5, value: ether });
    }
    catch(e) {
        console.error(e)
    }
    let result = await flightSuretyApp.hasPaidFee.call();

    // ASSERT
    assert.equal(result, true, "Airline should be able to pay fee");

  });


  it('registering a flight', async () => {

    // ARRANGE
    let flight = "CC 135";
    let result;

    // ACT
    try {
        await flightSuretyApp.registerFlight(airline3, flight, timestamp, STATUS_CODE_ON_TIME);
    }
    catch(e) {
        console.error(e)
    }

    // ASSERT

  });


  it('purchasing insurance', async () => {

      // ARRANGE
      let flight = "CC 135";
      let passenger = accounts[6];
      let amount = web3.utils.toWei("10", 'wei');
      let id;
      let key;

      // ACT
      try {
          key = await flightSuretyApp.getFlightKey(airline3, flight, timestamp)
          id = await flightSuretyApp.purchaseInsurance(key, amount, { from: passenger, value: amount })
      }
      catch(e) {
          console.error(e)
      }

      let blah = await flightSuretyApp.getInsuranceAmount(key, { from: passenger })

      // ASSERT
      assert.equal(blah, amount, "Amount not equal");

  })

  it('change flight status', async () => {

      // ARRANGE
      let flight = "CC 135";
      let status = STATUS_CODE_LATE_AIRLINE;
      let id;
      let key;

      // ACT
      try {
          key = await flightSuretyApp.getFlightKey(airline3, flight, timestamp)
          id = await flightSuretyApp.changeFlightStatus(key, status, { from: owner })
      }
      catch(e) {
          console.error(e)
      }

      let blah = await flightSuretyApp.getFlightStatus(key)

      // ASSERT
      assert.equal(blah, status, "Status has not been changed");

  })

  it('receive insurance payment', async () => {

      // ARRANGE
      let flight = "CC 135";
      let passenger = accounts[6];
      let id;
      let key;
      let amountGotten = web3.utils.toWei('15', 'wei');

      // ACT
      try {
          key = await flightSuretyApp.getFlightKey(airline3, flight, timestamp)
          id = await flightSuretyApp.receiveInsurancePayment(key, { from: passenger })
      }
      catch(e) {
          console.error(e)
      }

      let blah = await flightSuretyApp.getInsuranceReceived(key, { from: passenger })
      let blah2 = await flightSuretyApp.getInsuranceCredit({ from: passenger })

      // ASSERT
      assert.equal(blah, true, "Insurance hasn't been received");
      assert.equal(blah2, amountGotten, "Insurance hasn't been received");
  })

  it('withdraw insurance payment', async () => {

      // ARRANGE
      let flight = "CC 135";
      let passenger = accounts[6];
      let amount = await web3.utils.toWei('15', 'wei')
      let id;
      let key;

      console.log(await web3.eth.getBalance(passenger), "passenger money before")

      // ACT
      try {
          key = await flightSuretyApp.getFlightKey(airline3, flight, timestamp)
          id = await flightSuretyApp.withdrawInsurancePayment(amount, { from: passenger })
      }
      catch(e) {
          console.error(e)
      }

      console.log(await web3.eth.getBalance(passenger), "passenger money after")

      let blah = await flightSuretyApp.getInsuranceCredit({ from: passenger });

      // ASSERT
      assert.equal(blah, 0, "Insurance hasn't been withdrawn");

  });

});
