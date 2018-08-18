pragma solidity ^0.4.18;

contract DiceGame {
    /**每个房间可以进入N个人去玩,进去不需要触发存储(web)，等待所有人进去后开始才进行实际的记录操作;
       每个在某个房间的人可以用力摇骰子，摇的次数将作为随机数种子的一部分得出最后的骰子点数;
    对比房间所有人的点数，点数最大的人平均彩池的奖金。**/
    address public owner;//合约所有者

    event JoinSuccess(
        address indexed _from,
        uint _rollTime
    );
    //单个用户roll的结果
    struct DiceResult {
        address player;//玩家地址作为随机因素
        uint rollTime;//产生的时间作为随机因素
        uint shakeSeed;//用户摇骰子的次数作为随机因素
        uint8 result;//最终随机出来的结果
    }
    //多人摇骰子的结果组成赛果
    struct GameResult {
        mapping(uint=>DiceResult) diceResults;
        uint playerCount;
    }
    //房间
    struct Room{
        uint playerLimit; //人数上限
        uint stake;//下注额度
        string ptype; //玩法，目前固定就是拼大小
    }
    
    address[] internal agents;//记录哪些人是代理
    mapping(address=>Room[]) public agentToRooms;//记录谁开的房间,这是代理一级，进行线下推广的依据
    mapping(address=>mapping(uint=>GameResult[])) internal gameResults;//记录每个房间，每一局博弈的骰子情况

    constructor() public {
        owner = msg.sender;
        //demo 临时加入的代理
        agents.push(0x2932b7A2355D6fecc4b5c0B6BD44cC31df247a2e);
        agents.push(0x2191eF87E392377ec08E7c08Eb105Ef5448eCED5);
        agents.push(0x0F4F2Ac550A1b4e2280d04c21cEa7EBD822934b5);
        createRoom(agents[0],2,1,'ou');
        createRoom(agents[0],2,1,'ou');
        createRoom(agents[0],2,1,'ou');
        createRoom(agents[1],2,1,'ou');
        createRoom(agents[1],3,1,'ou');
        createRoom(agents[1],3,1,'ou');
        createRoom(agents[1],3,1,'ou');
        createRoom(agents[2],4,1,'ou');
        createRoom(agents[2],4,1,'ou');
        createRoom(agents[2],10,1,'ou');
        createRoom(agents[2],10,1,'ou');
        createRoom(agents[2],10,1,'ou');
        createRoom(agents[2],10,1,'ou');
        createRoom(agents[2],10,1,'ou');


    }
    //添加代理
    function addAgent(address agent) public {
        agents.push(agent);
    }
    //获取代理
    function getAgents() public view returns(address[]){
        return agents;
    }

    //创建房间
    function createRoom(address agent,uint playerLimit,uint stake,string ptype) public returns(uint) {
        return agentToRooms[agent].push(Room(playerLimit,stake,ptype)) - 1;
    }
    //获取某个地址拥有的房间数量,用于前端展示遍历的依据
    function getAgentRoomsCount(address agent) public view returns(uint){
        return agentToRooms[agent].length;
    }

    //获取某个房间的人数限制
    function getRoomPlayerLimit(address agent,uint roomNum) public view returns(uint){
        return agentToRooms[agent][roomNum].playerLimit;
    }

    //在一个房间新开一局游戏
    function newGameInRoom(address agent,uint roomNum) internal returns(uint){
        return gameResults[agent][roomNum].push(GameResult({playerCount:0}))-1;
    }

    //玩家准备开始游戏
    function readyPlay(address agent,uint roomNum,uint shakeSeed) public payable{
        require(msg.value == 1 ether);
        uint rollTime=now;
        GameResult[] storage roomGameRs=gameResults[agent][roomNum];
        if(roomGameRs.length==0){
            uint gnum=newGameInRoom(agent,roomNum);
            GameResult storage gr=roomGameRs[gnum];
            gr.diceResults[gr.playerCount]=DiceResult(msg.sender,rollTime,shakeSeed,0);
            gr.playerCount++;
        }else{
            gr=roomGameRs[roomGameRs.length-1];
            if(gr.playerCount<agentToRooms[agent][roomNum].playerLimit){
                gr.diceResults[gr.playerCount]=DiceResult(msg.sender,rollTime,shakeSeed,0);
                gr.playerCount++;
                if(gr.playerCount==agentToRooms[agent][roomNum].playerLimit){
                    //最后一个加入的玩家触发开始
                    roll(agent,roomNum);
                }
            }else{
                gnum=newGameInRoom(agent,roomNum);
                gr=roomGameRs[gnum];
                gr.diceResults[gr.playerCount]=DiceResult(msg.sender,rollTime,shakeSeed,0);
                gr.playerCount++;
            }
        }
        emit JoinSuccess(msg.sender,rollTime);
    }

    //生成随机骰子的点数
    function randDiceNum(address player,uint rollTime,uint shakeTotalSeed) public pure returns(uint8) {
        uint result=uint(keccak256(abi.encodePacked(rollTime, player, shakeTotalSeed))) % 6 + 1;
        return uint8(result);
    }

    //进行游戏
    function roll(address agent,uint roomNum) public {
        uint shakeTotal=0;
        GameResult[] storage roomGameRs=gameResults[agent][roomNum];
        GameResult storage gr=roomGameRs[roomGameRs.length-1];
        uint i;
        for (i=0; i < gr.playerCount; i++) {
            shakeTotal+=gr.diceResults[i].shakeSeed;
        }
        for (i=0; i < gr.playerCount; i++) {
            gr.diceResults[i].result=randDiceNum(gr.diceResults[i].player,gr.diceResults[i].rollTime,shakeTotal);
        }
    }

    //查询最近一局的某个人的点数
    function getLastGameResult(address agent,uint roomNum,uint idx) public view returns(address,uint,uint,uint8) {
        GameResult[] storage roomGameRs=gameResults[agent][roomNum];
        if(roomGameRs.length==0){
            return (0,0,0,0);
        }else{
            GameResult storage gr=roomGameRs[roomGameRs.length-1];
            DiceResult storage dr=gr.diceResults[idx];
            return (dr.player, dr.rollTime, dr.shakeSeed,dr.result);
        }
    }

    //判断输赢
    function judge(address agent,uint roomNum) public view returns(address[]){
        GameResult[] storage roomGameRs=gameResults[agent][roomNum];
        GameResult storage gr=roomGameRs[roomGameRs.length-1];
        uint points=1;
        uint i;
        for (i=0; i < gr.playerCount; i++) {
            if(gr.diceResults[i].result>points){
                points=gr.diceResults[i].result;
            }
        }
        uint wi=0;
        for (i=0; i < gr.playerCount; i++) {
            if(gr.diceResults[i].result==points){
                wi++;
            }
        }
        address[] memory winers=new address[](wi);
        wi=0;
        for (i=0; i < gr.playerCount; i++) {
            if(gr.diceResults[i].result==points){
                winers[wi]=gr.diceResults[i].player;
                wi++;
            }
        }
        return winers;
    }
}
