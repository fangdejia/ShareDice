var DiceGame = artifacts.require("./DiceGame.sol");

contract('DiceGame', async (accounts) => {
    it("...should have one player win at least.", async () => {
        let diceGame=await DiceGame.deployed();
        await diceGame.createRoom(accounts[0],4,1,"ou",{from: accounts[0]});
        let agents=await diceGame.getAgents.call({from:accounts[0]});
        for(let i=0;i<agents.length;i++){
            let roomCount=await diceGame.getAgentRoomsCount.call(agents[i]);
            console.log(`agent: ${agents[i]} has ${roomCount.toNumber()} room`);
        }
        let roomNum=0;
        let agent=agents[2];
        console.log(`play room number is :${agent},${roomNum}`);
        let event=diceGame.JoinSuccess();
        event.watch((err, result) => {
            emsg=result['args'];
            console.log(`receive event: ${emsg['_from']},ts:${emsg['_rollTime']}`);
            event.stopWatching();
        });
        await diceGame.readyPlay(agent,roomNum,124,{value: web3.toWei(1, "ether"),from:accounts[1]});
        await diceGame.readyPlay(agent,roomNum,24,{value: web3.toWei(1, "ether"),from:accounts[2]});
        await diceGame.readyPlay(agent,roomNum,30,{value: web3.toWei(1, "ether"),from:accounts[3]});
        await diceGame.readyPlay(agent,roomNum,224,{value: web3.toWei(1, "ether"),from:accounts[4]});
        let winers=await diceGame.judge.call(agent,roomNum,{from:accounts[0]});
        assert.equal(winers.length>=1,true, "No winner found!");
        console.log(`winers is :${winers}`);
        for(let i=0;i<4;i++){
            let rs=await diceGame.getLastGameResult.call(agent,roomNum,i);
            console.log([rs[0],rs[1].toNumber(),rs[2].toNumber(),rs[3].toNumber()]);
        }
    });

});
