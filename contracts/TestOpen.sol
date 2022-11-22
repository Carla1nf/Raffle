pragma solidity ^0.8.0;


contract TestOpen {

event Push(uint block, address sender);
event Recieve(uint block, address sender);


function Pushing() public {
    emit Push(block.timestamp, msg.sender);
}

function Recieving() public {
    emit Recieve(block.timestamp, msg.sender);
}

}