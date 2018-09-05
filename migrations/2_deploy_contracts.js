let SafeMath=artifacts.require("./library/SafeMath.sol");
let NameFilter=artifacts.require("./library/NameFilter.sol");
let PlayerBook=artifacts.require("./PlayerBook.sol");
let DiceGame=artifacts.require("./DiceGame.sol");
let ShareDiceGame=artifacts.require("./ShareDiceGame.sol");
module.exports = (deployer) => {
    deployer.deploy(SafeMath);
    deployer.deploy(NameFilter);
    deployer.deploy(DiceGame);
    deployer.link(SafeMath, [PlayerBook, ShareDiceGame]);
    deployer.link(NameFilter, [PlayerBook, ShareDiceGame]);
    deployer.deploy(PlayerBook);
    deployer.deploy(ShareDiceGame);
};
