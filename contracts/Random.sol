pragma solidity ^0.4.18;

contract Random {
    uint64 _seed = 0;
    function random(uint64 upper) public returns (uint64 randomNumber) {
        _seed=uint64(keccak256(abi.encodePacked(blockhash(block.number),_seed,now)));
        return _seed % upper;
    }

    function getRandomSeed() public returns (uint64 randomNumber) {
        _seed=uint64(keccak256(abi.encodePacked(blockhash(block.number),_seed,now)));
        return _seed;
    }
}
