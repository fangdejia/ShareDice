pragma solidity ^0.4.24;
import "./library/SafeMath.sol";
import "./library/NameFilter.sol";
contract PlayerBook {
    using NameFilter for string;
    using SafeMath for uint256;

    struct Player {
        address addr;
        bytes32 name;
        address laff;
    }

    address public owner;
    uint256 public registrationFee = 10 finney;//注册的花费
    uint256 public plyCount;//总注册人数
    mapping(address => uint256) public addr2pid; // (addr => pid) player id by address
    mapping(bytes32 => uint256) public name2pid;// (name => pid) player id by name
    mapping(uint256 => Player) public playerSet;// (pid => data) player data

    // 用户注册成功的事件
    event onNewName (
        address indexed playerAddr,
        bytes32 indexed playerName,
        uint256 amountPaid,
        uint256 timeStamp
    );

    modifier isOwner() {
        require(msg.sender==owner, "msg sender is not owner");
        _;
    }

    constructor() public {
        owner=msg.sender;
        _registerOrModifyName(owner,"sky",owner);
    }

    //注册或修改用户名
    function _registerOrModifyName(address addr,bytes32 name,address laff) internal {
         uint256 pid;
         if (name2pid[name] != 0){
            require(name2pid[name] == addr2pid[msg.sender], "sorry! you cant't change the other's name!");
            pid=name2pid[name];
         }
         else{
            plyCount++;
            pid=plyCount;
         }
        playerSet[pid].addr=addr;
        playerSet[pid].name=name;
        playerSet[pid].laff=laff;
        addr2pid[addr]=plyCount;
        name2pid[name]=plyCount;
        emit onNewName(addr, name, msg.value,now);
    }

    //注册用户
    function registerName(string name,address laff) public payable {
        require(msg.value >= registrationFee, "You have to pay the name fee!");
        bytes32 _name=name.nameFilter();
        _registerOrModifyName(msg.sender,_name,laff);
    }


    //检查用户名是否可用,UI一级使用
    function checkIfNameValid(string name) public view returns (bool) {
        bytes32 _name=name.nameFilter();
        return name2pid[_name] >0?true:false;
    }

    //设置注册用户名的费用
    function setRegistrationFee(uint256 _fee) isOwner() public {
        registrationFee = _fee;
    }

    function getPlayerName(uint256 pid) external view returns (bytes32) {
        return (playerSet[pid].name);
    }

    function getPlayerLAff(uint256 pid) external view returns (address) {
        return (playerSet[pid].laff);
    }

    function getPlayerAddr(uint256 pid) external view returns (address) {
        return (playerSet[pid].addr);
    }

}
