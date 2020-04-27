FlightSuretyApp = require('../../build/contracts/FlightSuretyApp.json');
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, "0xd6183B81f33409CcB096604F195E9F1D8e5340a9");

const App = {

    purchaseInsurance: async() => {
        await flightSuretyApp.purchaseInsurance();
    }

}
