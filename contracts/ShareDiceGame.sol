pragma solidity ^0.4.18;
import "./Random.sol";
import "./DiceDataStore.sol";

contract ShareDiceGame {
    address public owner;//合约所有者
    Random RDN;//随机合约

    //每期的参与者情况
    struct PalyerBetInfo {
        address player;//参与者地址
        uint256 joinTime;//加入时间
        uint256 ticketVol;//份数            
        uint256 winCount;//胜出的数量
        mapping(uint256=>uint8) resultSet;//每个骰子的点数
    }

    //每期的情况
    struct RoundInfo {
        mapping(uint256=>PalyerBetInfo) playerBetInfoSet;//每期包括的参与者
        uint256 playerCount;//参与者数量
        uint256 totalTicketVol;//总份数
        uint256 startTime;//开始时间
        uint256 winCount;//获胜者数量
        uint8 winDiceNum;//骰子最大的点数
        bool is_activate;//是否可用的
    }

    //总表
    mapping(uint256 => RoundInfo) public RoundSet; 
    uint256 public roundCount;//一共开了多少轮
    uint256 public baseUnit=0.01 ether;//每份的价格
    uint256 public roundInterval=1 minutes;//每期的间隔
    uint8 public commissionRate=5;//千分之五费率


    //使用事件记录每个玩家参与过的期数,或通知前端加入成功
    event JoinEvent(
        address indexed player,//参与者地址
        uint256 indexed roundNum,//参与第几期
        uint256 joinTime,//加入时间
        uint256 ticketVol//份数            
    );

    //结果通知
    event ResultEvent(
        address indexed player,//参与者地址
        uint256 indexed roundNum,//参与第几期
        uint256 ticketVol,//买入的份数
        uint256 winCount,//多少个赢了
        uint256 diceSeries,//骰子的随机序列
        uint256 payout,//支付额
        uint8 winDiceNum //获胜骰子最大的点数
    );

    modifier isOwner() {
        require(msg.sender==owner, "msg sender is not owner");
        _;
    }

    constructor(address randomAddr) public {
        owner=msg.sender;
        RDN=Random(randomAddr);
        for(uint256 i=0;i<3;i++){
            newRound(now+i*roundInterval);
        }
    }

    function kill() external {
        require(msg.sender==owner, "Only the owner can kill this contract");
        selfdestruct(owner);
    }

    //新开一期
    function newRound(uint256 startTime) private {
        roundCount++;
        RoundSet[roundCount].startTime=startTime;
        RoundSet[roundCount].is_activate=true;
    }

    /**获取当前总期数**/
    function getRoundCount() external view returns(uint256){
        return roundCount;
    }

    /**获取某一期的信息
      返回 期数，开始时间，参与者数量，总份数，此期是否活跃
    **/
    function getRoundInfo(uint256 roundNum) external view returns(uint256,uint256,uint256,uint256,bool){
        RoundInfo storage round=RoundSet[roundNum];
        uint256 ticketCount;
        for(uint256 i=0;i<round.playerCount;i++){
            ticketCount+=round.playerBetInfoSet[i].ticketVol;
        }
        return (roundNum,round.startTime,round.playerCount,ticketCount,round.is_activate);
    }

    //加入到
    function join(uint256 roundNum,uint256 ticketVol) external payable {
        require(msg.value>=ticketVol*baseUnit,"not enough ether!");
        RoundInfo storage round=RoundSet[roundNum];
        PalyerBetInfo storage plrBetInfo=round.playerBetInfoSet[round.playerCount];
        plrBetInfo.player=msg.sender;
        plrBetInfo.joinTime=now;
        plrBetInfo.ticketVol=ticketVol;
        round.totalTicketVol+=ticketVol;
        round.playerCount++;
        emit JoinEvent(msg.sender,roundNum,plrBetInfo.joinTime,ticketVol);
    }


    //开奖
    function settleRoundResult(uint256 roundNum) external payable {
        RoundInfo storage round=RoundSet[roundNum];
        require(now-round.startTime>=roundInterval && round.is_activate,'Settling round condition is not satify!');
        genenralRandomDice(round);
        calcWinCount(round);
        uint256 fundPool= round.totalTicketVol*baseUnit*(1000-commissionRate)/1000;
        round.is_activate=false;
        uint256 payout;
        uint256 diceSeries;
        for(uint i=0;i<round.playerCount;i++){//并支付相应的奖金
            diceSeries=0;
            for(uint j=0;j<round.playerBetInfoSet[i].ticketVol;j++){
                diceSeries+=round.playerBetInfoSet[i].resultSet[j]*10**j;
            }
            if(round.playerBetInfoSet[i].winCount>0){
                payout=fundPool*round.playerBetInfoSet[i].winCount/round.winCount;
                round.playerBetInfoSet[i].player.transfer(payout);//支付奖金
            }else{
                payout=0;
            }
            emit ResultEvent(round.playerBetInfoSet[i].player,roundNum,round.playerBetInfoSet[i].ticketVol,round.playerBetInfoSet[i].winCount,diceSeries,payout,round.winDiceNum);
        }
        newRound(now);
    }

    //统计每个人的输赢数
    function calcWinCount(RoundInfo storage round) private {
        uint256 winCount;
        uint256 totalWinCount;
        for(uint i=0;i<round.playerCount;i++){
            winCount=0;
            for(uint j=0;j<round.playerBetInfoSet[i].ticketVol;j++){
                if(round.playerBetInfoSet[i].resultSet[j]==round.winDiceNum){
                    winCount++;
                }
            }
            round.playerBetInfoSet[i].winCount=winCount;
            totalWinCount+=winCount;
        }
        round.winCount=totalWinCount;
    }

    //计算出随机骰子的结果
    function genenralRandomDice(RoundInfo storage round) private {
        uint64 seed=RDN.getRandomSeed();
        uint8 maxDiceNum;
        uint8 tempDiceNum;
        for(uint i=0;i<round.playerCount;i++){//生成随机结果，并记录最大的值
            for(uint j=0;j<round.playerBetInfoSet[i].ticketVol;j++){
                seed=uint64(keccak256(abi.encodePacked(blockhash(block.number),seed,round.playerBetInfoSet[i].joinTime)));
                tempDiceNum=uint8(seed%6)+1;
                round.playerBetInfoSet[i].resultSet[j]=tempDiceNum;
                maxDiceNum=tempDiceNum>maxDiceNum?tempDiceNum:maxDiceNum;
            }
        }
        round.winDiceNum=maxDiceNum;
    }

}

