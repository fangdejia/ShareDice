let PlayerBook=artifacts.require("./PlayerBook.sol");
contract('PlayerBook', (accounts) => {
    let playerBook;
    beforeEach('setup contract for each test', async function () {
        playerBook=await PlayerBook.deployed();
    })
    it('should return true when check the username exists!', async () => {
        let rst=await playerBook.checkIfNameValid.call('sky');
        assert.equal(rst,true);
    });
    it('should return false when check the username not exists!', async () => {
        let rst=await playerBook.checkIfNameValid.call('sky1');
        assert.equal(rst,false);
    });
    it('should register user successfully!', async () => {
        //注册名字
        await playerBook.registerName('jack',accounts[0],{value: web3.toWei(0.01, "ether"),from:accounts[1]});
        let rst=await playerBook.checkIfNameValid.call('jack');
        assert.equal(rst,true);
        //根据地址获取名字
        rst=await playerBook.getUserName.call({from:accounts[1]});
        assert.equal(rst,'jack');
    });
});
