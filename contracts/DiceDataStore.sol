pragma solidity ^0.4.24;
contract DiceDataStore {
    //每期的参与者情况
    struct PalyerBetInfo {
        address player;//参与者地址
        uint256 joinTime;//加入时间
        uint256 ticketVol;//份数            
        uint256 winCount;//胜出的数量
        mapping(uint256=>int8) resultSet;//每个骰子的点数
    }

    //每期的情况
    struct RoundInfo {
        mapping(uint256=>PalyerBetInfo) playerBetInfoSet;//每期包括的参与者
        uint256 playerCount;//参与者数量
        uint256 startTime;//开始时间
        uint256 winCount;//获胜者数量
        uint8 winDiceNum;//骰子最大的点数
        bool is_activate;//是否可用的
    }

    //总表
    mapping(uint256 => RoundInfo) public RoundSet; 
    uint256 public roundCount;//一共开了多少轮


    //使用事件记录每个玩家参与过的期数,或通知前端加入成功
    event JoinEvent(
        address indexed player,//参与者地址
        uint256 roundNum,//参与第几期
        uint256 joinTime,//加入时间
        uint256 ticketVol//份数            
    );

    //结果通知
    event ResultEvent(
        address indexed player,//参与者地址
        uint256 roundNum,//参与第几期
        uint256 winCount,//多少个赢了
        uint256 diceSeries,//骰子的随机序列
        uint256 payout,//支付额
        uint8 winDiceNum //获胜骰子最大的点数
    );

}
