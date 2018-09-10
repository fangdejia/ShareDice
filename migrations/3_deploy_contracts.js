let SafeMath=artifacts.require("./library/SafeMath.sol");
let NameFilter=artifacts.require("./library/NameFilter.sol");
let PlayerBook=artifacts.require("./PlayerBook.sol");
let DiceGame=artifacts.require("./DiceGame.sol");
let ShareDiceGame=artifacts.require("./ShareDiceGame.sol");
let Random=artifacts.require("./Random.sol");
let DiceDataStore=artifacts.require("./DiceDataStore.sol");

module.exports = (deployer) => {
    deployer.deploy(DiceGame);
    deployer.deploy(SafeMath);
    deployer.deploy(NameFilter);
    deployer.link(SafeMath, [PlayerBook, ShareDiceGame]);
    deployer.link(NameFilter, [PlayerBook, ShareDiceGame]);
    deployer.deploy(PlayerBook);
    deployer.deploy(ShareDiceGame,Random.address);
};
