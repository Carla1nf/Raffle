const Mint = artifacts.require("Mint");

contract("Mint NFt", () => {
    it("Deploy & Mint", async () => {
        const mint = await Mint.deployed();
        await mint.mint();
        await mint.mint();
        await mint.mint();
        await mint.mint();
        await mint.mint();
        await mint.mint();
        await mint.mint();
        await mint.mint();
        const add =  mint.address;
        console.log(add);
    })
})