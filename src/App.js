import React, { Component } from 'react'
import DiceGame from '../build/contracts/DiceGame.json'
import getWeb3 from './utils/getWeb3'

import './css/oswald.css'
import './css/open-sans.css'
import './css/pure-min.css'
import './App.css'
class ListRoom extends Component {
    render() {
        let atr=this.props.agentToRooms;
        if(atr){
            let lis=[];
            for(let agent in atr) {
                if (atr.hasOwnProperty(agent)) {
                    lis.push(<li key={agent}>代理:{agent}开放的房间</li>)
                    let agentRooms=atr[agent];
                    for(let i=0;i<agentRooms;i++){
                        lis.push(<li key={agent+'-'+i} onClick={() => this.props.getInRoom(agent,i)}><button >第{i}号房间</button></li>);
                    }
                }
            }
            return (
                <div className="pure-u-1-1">
                    <h2>房间列表</h2>
                    <ul key="listroom">
                        {lis}
                    </ul>
                </div>
            );
        }else{
            return null;
        }
    }
}

class ListPlayer extends Component {
    render() {
        //根据进入的房间进行展示情况
        //要查询这间房间可容纳多少人，多少人已经就绪
        //有点击按钮返回大厅，有准备开始按钮
        let playerTemplate=[];
        let lgr=this.props.lastGameResult
        let lgrLength=lgr.length;
        if(this.props.joinState==='unjoined'){
            playerTemplate.push(<li key="join"><input placeholder="输入你的幸运数字" type="text" onChange={this.props.recordShakeSeed}/>&nbsp;<button onClick={() => this.props.readyPlay()}>摇骰子</button></li>);
        }else{
            if(this.props.joinState==='joined'){
                if(lgrLength===this.props.playerLimit){
                    playerTemplate.push(<li key={'joined'}>结果已生成!</li>);
                }else{
                    playerTemplate.push(<li key={'joined'}>你已经申请加入，等待结果!</li>);
                }
            }else{
                for(let i=0;i<this.props.playerLimit;i++){
                    if(i<lgrLength && lgrLength!==this.props.playerLimit){
                        playerTemplate.push(<li key={i}>玩家:{lgr[i][0]}已加入</li>);
                    }else{
                        playerTemplate.push(<li key={i}>等待玩家<button onClick={() => this.props.join()}>加入</button></li>);
                    }
                }
            }
        }

        let lastgrTemplate=[];
        if(lgrLength===this.props.playerLimit){
            for(let i=0;i<lgrLength;i++){
                let gr=lgr[i];
                lastgrTemplate.push(<li key={i}>玩家:{gr[0]},幸运数字:{gr[2]},摇出骰子点数为{gr[3]}</li>);
            }
        }
        return (
            <div className="pure-u-1-1">
                <h2>当前房间{this.props.inRoomAgent + '---' + this.props.inRoomNum}号房间</h2>
                <button onClick={() => this.props.getOutRoom()}>返回大厅</button>
                <ul>
                    {playerTemplate}
                </ul>
                <ul>最近一次结果,获胜者为:{this.props.lastWiner.join(" 和 ")}
                    {lastgrTemplate}
                </ul>
            </div>
        );
    }
        //点击开始后，调用以太坊支付接口进行下注
        //展示游戏结果
}

class App extends Component {
    constructor(props) {
        super(props);
        //joinState 有几种状态，watch,unjoin,joined
        this.state = { account:null,agents:[], agentToRooms:{}, web3: null,isInRoom:false,joinState:'watch',
                       inRoomAgent:null,inRoomNum:-1,playerLimit:0,inPalyerCount:0,shakeSeed:null,lastGameResult:[],lastWiner:[]};
        this.diceGame = null;
    }

    componentWillMount() {
        getWeb3.then(results => {
            this.setState({ web3: results.web3 });
            this.instantiateContract();
        }).catch((e) => {
            console.error("Exception thrown", e.stack);
            console.log('Error finding web3.');
        });
    }

    instantiateContract() {
        const contract = require('truffle-contract');
        const DiceGameClass = contract(DiceGame);
        DiceGameClass.setProvider(this.state.web3.currentProvider);
        let diceGame;
        this.agentToRooms={};
        this.state.web3.eth.getAccounts((error, accounts) => {
            this.setState({account:accounts[0]});
            DiceGameClass.deployed().then((instance) => {
                diceGame=instance;
                this.diceGame=instance;
            }).then(() => {
                diceGame.getAgents.call().then((result) => {
                    this.setState({agents:result});
                    console.log(this.state.agents);
                    for(let i=0;i<this.state.agents.length;i++){
                        let agent=this.state.agents[i];
                        diceGame.getAgentRoomsCount.call(agent).then((roomCount) => {
                            this.agentToRooms[agent]=roomCount.toNumber();
                            if(i===this.state.agents.length-1){
                                this.setState({agentToRooms:this.agentToRooms});
                                console.log(this.state.agentToRooms);
                            }
                        });
                    }
                });
            });
        });
    }

    getLastGameResult(agent,roomNum){
        let lastGameResult=[];
        for(let i=0;i<this.state.playerLimit;i++){
            this.diceGame.getLastGameResult.call(agent,roomNum,i).then((result) => {
                if(result[0]!=="0x0000000000000000000000000000000000000000"){
                    lastGameResult.push([result[0],result[1].toNumber(),result[2].toNumber(),result[3].toNumber()]);
                }
                if(i===this.state.playerLimit-1){
                    console.log(lastGameResult);
                    this.setState({lastGameResult:lastGameResult});
                }
            });
        }
    }

    getInRoom(agent,roomNum) {
        this.setState({inRoomAgent:agent,inRoomNum:roomNum,isInRoom:true});
        this.diceGame.getRoomPlayerLimit.call(agent,roomNum).then((result) => {
            this.setState({playerLimit:result.toNumber()});
        });
    }
    getOutRoom() {
        this.setState({isInRoom:false,inRoomAgent:null,inRoomNum:-1,joinState:'watch',playerLimit:0,inPalyerCount:0,shakeSeed:null,lastGameResult:[],lastWiner:[]});
    }

    recordShakeSeed(e) {
        const value = e.target[e.target.type === "checkbox" ? "checked" : "value"];
        this.setState({shakeSeed:value});
    }

    readyPlay() {
        this.diceGame.readyPlay(this.state.inRoomAgent,this.state.inRoomNum,this.state.shakeSeed,{value: this.state.web3.toWei(1, "ether"),from:this.state.account}).then(() => {
            this.setState({joinState:'joined'});
        }).then(() => {
            //let event=this.diceGame.JoinSuccess();
            //event.watch((err, result) => {
                //let emsg=result['args'];
                //console.log(`receive event: ${emsg['_from']},ts:${emsg['_rollTime']}`);
                //this.setState({joinState:'joined'});
                //event.stopWatching();
            //});
        });
    }

    componentDidMount() {
        this.interval = setInterval(() => {
            if(this.state.inRoomAgent){
                this.getLastGameResult(this.state.inRoomAgent,this.state.inRoomNum);
                this.diceGame.judge.call(this.state.inRoomAgent,this.state.inRoomNum).then((result) => {
                    console.log(`judge result:${result}`);
                    this.setState({lastWiner:result});
               });
            };
        }, 1000);
    }

    componentWillUnmount() {
        clearInterval(this.interval);
    }

    render() {
        return (
            <div className="App">
                <nav className="navbar pure-menu pure-menu-horizontal">
                    <a href="#" className="pure-menu-heading pure-menu-link">Share Dice</a>
                </nav>

                <main className="container">
                    <div className="pure-g">
                        <div className="pure-u-1-1">
                            <h1>游戏规则</h1>
                            <ul>
                                <li>1、进入房间，等待该房间足够玩家全部加入(存入以太币到彩池)后，进行摇骰子游戏；</li>
                                <li>2、每人玩家分配一个骰子，摇到最高点数的玩家获的彩池所有奖金,；</li>
                                <li>3、每个玩家摇骰子的结果受到所有玩家输入的幸运数字和自身加入时间影响，从而保证游戏的随机性和公平性；</li>
                                <li>4、所有下注信息均公开存储在以太坊智能合约里面，任何人可以查看验证下注的原始信息；</li>
                                <li>5、平台收取获胜玩家千分之五奖金作为手续费.</li>
                            </ul>
                        </div>
                        {this.state.isInRoom?<ListPlayer getOutRoom={() => this.getOutRoom()} join={() => this.setState({joinState:'unjoined'})} readyPlay={() => this.readyPlay()} recordShakeSeed={(e) => this.recordShakeSeed(e)}
                            inRoomAgent={this.state.inRoomAgent} playerLimit={this.state.playerLimit} inRoomNum={this.state.inRoomNum} joinState={this.state.joinState} lastGameResult={this.state.lastGameResult} lastWiner={this.state.lastWiner}/>:
                            <ListRoom agentToRooms={this.state.agentToRooms} getInRoom={(agent,roomNum) => this.getInRoom(agent,roomNum)}/>}
                    </div>
                </main>
            </div>
        );
    }
}

export default App
