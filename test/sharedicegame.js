let ShareDiceGame = artifacts.require("./ShareDiceGame.sol");
let truffleAssert = require('truffle-assertions');
function sleep (time) {
    return new Promise((resolve) => setTimeout(resolve, time));
}
contract('ShareDiceGame', (accounts) => {
    let diceGame;
    let owner;
    beforeEach('setup contract for each test', async () => {
        diceGame=await ShareDiceGame.deployed();
        let web3Contract=web3.eth.contract(diceGame.abi).at(diceGame.address);
        owner=web3Contract._eth.coinbase;
    });

    it('should have three round!', async () => {
        //获取当前最大的期数,对应页面显示需要显示最近3期的逻辑
        let roundCount = await diceGame.getRoundCount.call();
        assert.equal(roundCount,3, "No round found!");
        for(let i=1;i<4;i++){
            //获取某期的具体信息,包括信息:期数，开始时间，参与者数量，总份数，此期是否活跃
            let rinfo= await diceGame.getRoundInfo.call(i);
            console.log(rinfo.slice(0,4).map(val=>val.toNumber()));
        }
    });
    it('should rand dice successfully!!', async () => {
        let ticketVol=10;
        let roundNum=1;
        //用户进行投注
        let tx = await diceGame.join(roundNum,ticketVol,{value: web3.toWei(0.01*ticketVol, "ether"),from:accounts[0]});
        truffleAssert.eventEmitted(tx, 'JoinEvent', (ev) => {
            //投注成功后的事件通知,包括信息: 参与者地址,参与第几期,加入时间,购买份数
            //console.log(ev.joinTime.toNumber());
            return ev.player === accounts[0] && ev.roundNum.toNumber() === roundNum && ev.ticketVol.toNumber() === ticketVol;
        });
        //第二个加入者
        ticketVol=5;
        tx = await diceGame.join(roundNum,ticketVol,{value: web3.toWei(0.01*ticketVol, "ether"),from:accounts[1]});
        truffleAssert.eventEmitted(tx, 'JoinEvent', (ev) => {
            //console.log(ev.joinTime.toNumber());
            return ev.player === accounts[1] && ev.roundNum.toNumber() === roundNum && ev.ticketVol.toNumber() === ticketVol;
        });

        //查询历史事件,这里的方法可以用于查询某个某期的投注情况，和历史投注结果:对应事件改为ResultEvent即可
        console.log(`=========展示历史投注信息owner:${owner}==========`);
        //可以指定索引字段作为过滤字段
        let filter=diceGame.JoinEvent({_from: owner,player:accounts[1]}, {fromBlock: 0, toBlock: 'latest'});
        filter.get((error,log) => {
            console.log(log);
        });
        filter.stopWatching();

        await sleep(60000);
        console.log("=========驱动到期的某一期结算==========");
        tx = await diceGame.settleRoundResult(roundNum,{from:accounts[2]});
        truffleAssert.eventEmitted(tx, 'ResultEvent', (ev) => {
            console.log(ev);
            return ev.payout >0;
        });
    });
});
