pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";

contract Azuki is ERC721A {
    constructor() ERC721A("Azuki", "AZUKI") {}

    function mint(uint256 quantity) external payable {
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(msg.sender, quantity);
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        
        return "ipfs://QmQcooSUvYEJ8cLRfQZHjbEvtAL5t9yehCpwNqUD7q6rfb/13.json";
    }
}