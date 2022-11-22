const { assert } = require("chai");

const Raffle = artifacts.require("Raffle");
const Verification = artifacts.require("Verification");

require("chai")
.use(require("chai-as-promised"))
.should()



contract("Raffle Contract", (accounts) => {


    it("Deploy Raffle & Verification", async () => {
        const raffle = await Raffle.deployed();
        const raffleAdd = await raffle.address;
        console.log(raffleAdd);
    })

})