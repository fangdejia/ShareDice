require('babel-register');
let HDWalletProvider = require("truffle-hdwallet-provider");
let mnemonic="engage solve diet staff equal pulp guess album engine reject treat brief";
module.exports = {
    networks: {
        //development: {
            //host: "localhost",
            //port: 8545,
            //network_id: "*"
        //},
        development: {
            provider: new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/",0,5),
            network_id: 4,
            gas: 4612388
        },
        rinkeby: {
            provider: new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/",0,5),
            network_id: 4,
            gas: 4612388
        }
  }
};
