pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

error YouAreNotTheOwner();

contract Staking is ERC1155Holder {



mapping(uint => address) tokenIdOwner;
mapping(address => uint) stakedCount;
mapping(address => uint) reclaimed;
mapping (address => uint) debt;
mapping (address => uint[]) public nftsId;

uint private nftsStaked;
uint private pool;
uint private poolPerNFT;
IERC1155 public nftAddress;
address private owner;

constructor() {
    owner = msg.sender;
}

modifier onlyOwner() {

require(msg.sender == owner);
_;

}




fallback() external payable {


}

 
function stake(uint[] memory _nftIds, uint[] memory amounts) public  {
    Updated(msg.sender);
    IERC1155 sCollection = IERC1155(nftAddress);
    sCollection.safeBatchTransferFrom(msg.sender, address(this), _nftIds, amounts, "");
    stakedCount[msg.sender] += _nftIds.length;
    nftsStaked += _nftIds.length;

    for(uint i = 0; i < _nftIds.length; i++) {

    tokenIdOwner[ _nftIds[i]] = msg.sender;
    nftsId[msg.sender].push( _nftIds[i]);
    }
}



function deposit() public payable  {

pool += msg.value;
poolPerNFT = pool / nftsStaked;

 }

function withdraw(uint[] memory _nftIds, uint[] memory amounts) public  {
    Updated(msg.sender);
    IERC1155 sCollection = nftAddress;

    for(uint i = 0; i < _nftIds.length; i++) {

   if(tokenIdOwner[_nftIds[i]] == msg.sender)  {

    delete tokenIdOwner[_nftIds[i]];

  } else {
    revert YouAreNotTheOwner();  
   }

}
    stakedCount[msg.sender] -= _nftIds.length;
    nftsStaked -= _nftIds.length;
    sCollection.safeBatchTransferFrom(address(this), msg.sender, _nftIds, amounts, "");


}

function claimFunds() public  {
Updated(msg.sender);
if(debt[msg.sender] == 0) {
    revert();
}

uint funds = debt[msg.sender];
debt[msg.sender] = 0;
(bool success,) = msg.sender.call{value: funds}("");
if(!success) {
    revert();
}
}

function StakedNft(address _add) public view returns(uint[] memory) {
   uint[] memory actualIds = new uint[] (nftsId[_add].length);


for(uint i; i < actualIds.length; i++) {
    if(tokenIdOwner[nftsId[_add][i]] == msg.sender) {
        actualIds[i] = nftsId[_add][i];
    }
}

    return actualIds; 

}

function totalStaked(address _add) public view returns(uint[] memory) {
uint[] memory Data = new uint[](4);

for(uint i; i < 4; i++) {
    if(i == 0) {
        Data[i] = nftsStaked;
    } else if(i == 1) {
        Data[i] = stakedCount[_add];
    } else if(i == 2) {
        Data[i] = pool;
    } else if(i == 3) {
        Data[i] = (debt[_add] + (poolPerNFT - reclaimed[_add]) * stakedCount[_add]);
    }
}

return Data;

}

function unReclaimed(address add) public view returns(uint256) {
    return  debt[add] + (poolPerNFT - reclaimed[add]) * stakedCount[add];
}

function setNft(address nft) public onlyOwner {
    nftAddress = IERC1155(nft);
}

function Updated(address add) internal {
debt[add] += (poolPerNFT - reclaimed[add]) * stakedCount[add];
reclaimed[add] = poolPerNFT;
}

}