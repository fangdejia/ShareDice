var SimpleStorage = artifacts.require("./SimpleStorage.sol");
var DiceGame = artifacts.require("./DiceGame.sol");

module.exports = function(deployer) {
  deployer.deploy(SimpleStorage);
  deployer.deploy(DiceGame);
};
