import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';


let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);


let accounts = await this.web3.eth.getAccounts();
for(let i = 1; i < 25; i++) {
    flightSuretyApp.registerOracle({ from: accounts[i] })
}

async getFlightStatus(request) {
    let response = {};
    response.index = request.index;
    response.airline = request.airline;
    response.flight = request.flight;
    response.timestamp = request.timestamp;

    let reportedStatuses = [];
    flightSuretyApp.oracles.forEach(oracle => {
        let status = oracle.getFlightStatus(request);
        if(status) reportedStatuses.push(status);
    });

    return reportedStatuses;
}


flightSuretyApp.events.OracleRequest({
    fromBlock: 0
  }, function (error, event) {
    if (error) console.log(error)
    console.log(event)
});

const app = express();
app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
})

export default app;
