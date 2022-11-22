pragma solidity ^0.8.0;

interface IStaking {

function deposit() external payable;

}


contract Testing {
    
    function test(address staking) public payable {
        IStaking stakings = IStaking(staking);
        stakings.deposit{value: msg.value}();
    }
}