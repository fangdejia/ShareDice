var ShareDiceGame = artifacts.require("./ShareDiceGame.sol");

contract('ShareDiceGame', async (accounts) => {
    console.log("fuck");
    let diceGame=await ShareDiceGame.deployed();
    it("...should have one player win at least.", async () => {
    });

});
