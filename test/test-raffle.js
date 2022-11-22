const { assert } = require("chai");

const Raffle = artifacts.require("Raffle");
const Mint = artifacts.require("Mint");
const Azuki = artifacts.require("Azuki");
const xERC721 = artifacts.require("xERC721");
const Staking = artifacts.require("Staking");


require("chai")
.use(require("chai-as-promised"))
.should()



contract("Raffle Contract", (accounts) => {

    it("Deploy NFT & Mint", async () => {
const mint = await Mint.deployed();
await mint.mint();
await mint.mint({from: accounts[4]});
const balance = await mint.balanceOf(accounts[4], 2);
assert.equal(balance, 1, "Not Minted");
    })


    it("Deploy Raffle", async () => {
        const raffle = await Raffle.deployed({from: accounts[2]});
        const address = await raffle.address;
        console.log(address)
    }),

    it("Mint ERC721A", async () => {
        const azuki = await Azuki.deployed();
        await azuki.mint(1);



    }),
    
    it("Mint ERC721", async () => {
        const xerc721 = await xERC721.deployed();
        await xerc721.mint();



    }),

    it("Start Raffle", async () => {
        const raffle = await Raffle.deployed({from: accounts[2]});
        const mint = await Mint.deployed();
        const xerc721 = await xERC721.deployed();
        const raffleAdd = await raffle.address;
        const azuki = await Azuki.deployed();
        await azuki.setApprovalForAll(raffleAdd, true);
        await xerc721.setApprovalForAll(raffleAdd, true);
        await mint.setApprovalForAll(raffleAdd, true);
        await mint.setApprovalForAll(raffleAdd, true, {from: accounts[4]});
        const collectionAddress = await mint.address;
        const secondAdd = await azuki.address;
        const thirdAdd = await xerc721.address;
        const fundsB = await web3.eth.getBalance(raffleAdd);
        await raffle.startYourRaffle(100, "10000000000000000", collectionAddress, 2, 1, 1800, {value: 20000000000000000, from: accounts[4]});
        await raffle.startYourRaffle(100, "10000000000000000", collectionAddress, 1, 1, 1800,{value: 20000000000000000});
        await raffle.startYourRaffle(100, "10000000000000000", secondAdd, 0, 2, 1800, {value: 20000000000000000});
        await raffle.startYourRaffle(100, "10000000000000000", thirdAdd, 0, 0, 1800, {value: 20000000000000000});
        const fundsA = await web3.eth.getBalance(raffleAdd);
         console.log(fundsA, fundsB);

    }),

    it("Stake", async () => {
        const mint = await Mint.deployed();
        const raffle = await Raffle.deployed();
        const staking = await Staking.deployed();
        const addressSt = await staking.address;
        await raffle.setStaking(addressSt);
        await mint.mint();
        await mint.setApprovalForAll(addressSt, true);
        const addressMint = await mint.address
        await staking.setNft(addressMint);
        await staking.stake([3], [1]);
            }),
        

    it(" Buy Tickets and Return total & available Tickets per raffle",  async () => {
        const raffle = await Raffle.deployed();
        const raffleID = await raffle.getRaffle(1);
        const tickets = raffleID.tickets;
        await raffle.buyTickets(1, 2, {value: 20000000000000000});
        const realPlayers = await raffle.realPlayersPerRaffle(1);
        await raffle.buyTickets(1, 2, {value: 20000000000000000, from: accounts[2]});
        await raffle.buyTickets(1, 90).should.be.rejected;
        await raffle.buyTickets(1, 10, {value: 80000000000000000}).should.be.rejected;
        const raffleIs = await raffle.getRaffle(1);
        const boughtTickets = raffleIs.ticketsBought;
       await raffle.buyTickets(1, 10, {value: 100000000000000000, from: accounts[3]});
       const transaction = await raffle.buyTickets(1, 50, {value: 500000000000000000, from: accounts[2]});
      const player = await raffle.players(1, 63);
      console.log(player);
      console.log(accounts[2]);
       console.log(transaction.receipt.gasUsed);
        assert.equal(realPlayers, 1, "Adding Count is not Working");
        assert.equal(tickets, 100, "Is not giving back the expected amount of tickets");
        assert.equal(boughtTickets, 4, "Is not giving back the expected amount of tickets")
    }),

    /* it("Random Tickets is working", async () => {
        const raffle = await Raffle.deployed();
        const bBalance = await web3.eth.getBalance(accounts[0]);
        await raffle.requestWinner(1, {from: accounts[0]});
        const aBalance = await web3.eth.getBalance(accounts[0]);
        const result = aBalance - bBalance;
        console.log(result);
        
    }), */

    it("Check Raffle",  async () => {
  
        const raffle = await Raffle.deployed();
      const struct =  await raffle.getRaffle(1);

    }),


    it("Refund Raffle", async () => {
        const raffle = await Raffle.deployed();
        const mint = await Mint.deployed();
    /*    await raffle.getFunds(2, {from: accounts[0]}).should.be.rejected; */
        await raffle.refund(1, {from: accounts[0]}).should.be.rejected;
        const fundsB = await web3.eth.getBalance(accounts[0]);
        await raffle.refund(2, {from: accounts[1]}).should.be.rejected;
        await raffle.refund(2, {from: accounts[0]});
        const fundsA = await web3.eth.getBalance(accounts[0]);
        const result = fundsA - fundsB;
        const balance = await mint.balanceOf(accounts[0], 1);
        assert.equal((result > 19000000000000000 && 20000000000000000 > result ), true)
        assert.equal(balance, 1, "Nft did not come back");


    })

  /*  it("Get Funds", async () => {
        const raffle = await Raffle.deployed();
        const balanceB = await web3.eth.getBalance(accounts[4]);
        await raffle.getFunds(1, {from: accounts[4]});
        const balanceA = await web3.eth.getBalance(accounts[4]);
        const result = balanceA - balanceB
        console.log(result);


    }),

    it("Check Debt", async () => {
const staking = await Staking.deployed();
const raffle = await Raffle.deployed();
const debt = await staking.unReclaimed(accounts[0]);
const stakinA = await raffle.getStaking();
const addressSt = await staking.address;


console.log(debt.toString());
console.log(stakinA);
console.log(addressSt);


}) */
})