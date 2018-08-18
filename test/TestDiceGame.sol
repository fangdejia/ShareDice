pragma solidity ^0.4.18;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/DiceGame.sol";

contract TestDiceGame {

  function testCreateRoom() public {
    DiceGame diceGame = DiceGame(DeployedAddresses.DiceGame());
    uint beforeRoomCount=diceGame.getAgentRoomsCount(msg.sender);
    diceGame.createRoom(msg.sender,2,1,"ou");
    uint afterRoomCount=diceGame.getAgentRoomsCount(msg.sender);
    Assert.equal(afterRoomCount, beforeRoomCount+1, "It should be more rooms!");
  }

  function testRandDiceNum() public {
    DiceGame diceGame = DiceGame(DeployedAddresses.DiceGame());
    uint diceNum=diceGame.randDiceNum(msg.sender,now,30);
    Assert.isAtLeast(diceNum, 1, "It should at least equal 1!");
    Assert.isAtMost(diceNum, 6, "It should at most equal 6!");
  }

  //function testDiceGame() public {
    //DiceGame diceGame = DiceGame(DeployedAddresses.DiceGame());
    //address agent=msg.sender;

    //uint roomNum=diceGame.createRoom(agent,4,1,"ou");
    //diceGame.readyPlay(agent,roomNum,124);
    //diceGame.readyPlay(agent,roomNum,1);
    //diceGame.readyPlay(agent,roomNum,30);
    //diceGame.readyPlay(agent,roomNum,224);
    //address[] memory winers=diceGame.judge(agent,roomNum);
    //Assert.isAtLeast(winers.length, 1, "It should at least one winer!");
  //}

}
