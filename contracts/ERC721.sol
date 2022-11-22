pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract xErc721 is ERC721 {

uint id;
constructor() ERC721("Nft Test", "NFT") {

}

function mint() public {
    _mint(msg.sender, id);
    id++;
}


function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        
        return "ipfs://QmQcooSUvYEJ8cLRfQZHjbEvtAL5t9yehCpwNqUD7q6rfb/12.json";
    }


}