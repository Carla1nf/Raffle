pragma solidity >= 0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}



contract Mint is ERC1155 {

constructor() ERC1155("ipfs://QmVc99YsVjjo23h5BLHrckQ7YHjPx6P4G969mpL3jipnTX/{id}.json") {
    
    owner = msg.sender;
    
}

uint public totalSupply = 0;
uint public MAX_Supply = 20;
bool reveal = false;
bool pause = true;
string public unrevealedUri = "";
string public baseUri = "";
address owner;
uint price = 1 ether;
uint whitelistPrice = 0.05 ether;
uint preOrderPrice = 0.06 ether;
uint preOrderAmount;
uint preOrderFunds;

bytes32 public merkleRoot = 0x2f99b4d0dbbde6a3f61676f738d5dce71885a0738b304aae14a3041e1c4e47fb;

mapping(address => bool) public whitelistBought;
mapping(address => uint) public preOrderUnits;
mapping(address => mapping(uint => uint)) public preOrderTime;

event Minting(address minter, uint block);


modifier onlyOwner() {
  msg.sender == owner;
 
  _;
}

function mintWhitelist(bytes32[] memory merkleProof) public payable {

  bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
require(MerkleProof.verify(merkleProof, merkleRoot, leaf));
    totalSupply++;
_mint(msg.sender, totalSupply, 1, "");



}


function mint() public {
     totalSupply++;
    _mint(msg.sender, totalSupply, 1, "");
 
}


function withdraw() external payable onlyOwner {
  uint funds = address(this).balance - preOrderFunds;
  payable(msg.sender).transfer(funds);

  }




  function refund(uint amount) public payable {
      require(tx.origin == msg.sender);
      require(preOrderUnits[msg.sender] >= amount);
      require(pause == true);

     uint units = preOrderUnits[msg.sender];


   // 6000 blocks per day => 42000 blocks per week => 84000 blocks per 2 weeks

      for(uint i = 0; i < amount; i++) {
        if(preOrderTime[msg.sender][units - (1 + i)]  > block.timestamp) {

          preOrderAmount--;
          preOrderUnits[msg.sender]--;
          preOrderFunds -= preOrderPrice;
          payable(msg.sender).transfer(preOrderPrice);
        } 

}


  }


function preOrder(uint amount) public payable {

  require(tx.origin == msg.sender);
  require(amount > 0);
  require(msg.value == preOrderPrice * amount);
  require(preOrderAmount + amount <= 500);
  require( 10 >= preOrderUnits[msg.sender] + amount);

preOrderUnits[msg.sender] += amount;
preOrderAmount += amount;
preOrderFunds += amount * preOrderPrice;
for(uint i = 0; i < amount; i++) {
preOrderTime[msg.sender][preOrderUnits[msg.sender] - (1 + i)] = (block.timestamp) + 5 seconds;


}






}

function hPreOrderFunds() public  view onlyOwner returns(uint) {
return preOrderFunds;
}

function _pause() public onlyOwner {
  pause = !pause;
}

function setUnrevealedUri(string memory _unrevealedUri) public onlyOwner {
  unrevealedUri = _unrevealedUri;
}

function setBaseUri(string memory _baseuri) public onlyOwner {
  baseUri = _baseuri;
}

function returnUnreaveledUri() public view returns(string memory) {
  return unrevealedUri;
}

function returnBase() public view returns(string memory){

  return baseUri;
}

function returnMaxSupply() public view returns(uint) {
  return MAX_Supply;
}

function returnTotalSupply() public view returns(uint) {
  return totalSupply;
}

function photosReveal() public onlyOwner{
  reveal = !reveal;
}

function returnPrice() public view returns(uint) {
  return price;
}



function reduceSupply(uint newMaxSupply) public onlyOwner {
require(totalSupply <= newMaxSupply);
require(MAX_Supply > newMaxSupply);
MAX_Supply = newMaxSupply;
}


function setPrice(uint newPrice) public onlyOwner {
price = newPrice;
}

function uri(uint id) public virtual view override returns(string memory) {
  
  if(reveal == false) {
      return string(unrevealedUri);
  }else {
    return string(
        abi.encodePacked(baseUri,
        Strings.toString(id),
        ".json")
    );
  }





} 







}