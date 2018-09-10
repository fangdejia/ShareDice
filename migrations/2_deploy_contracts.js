let Random=artifacts.require("./Random.sol");
let DiceDataStore=artifacts.require("./DiceDataStore.sol");

module.exports = (deployer) => {
    deployer.deploy(Random);
    deployer.deploy(DiceDataStore);
};
