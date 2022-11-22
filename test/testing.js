const Verification = artifacts.require("Verification");


contract("Check Multi-Contracts", (accounts) => {

    it("Deploy & Test", async () => {
     const testing = await Verification.deployed();

     console.log(testing.address);
 

    })
})