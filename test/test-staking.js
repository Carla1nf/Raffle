
const Staking = artifacts.require("Staking");




contract("Test Staking", () => {

it("Deploy & Mint", async () => {

    const staking = await Staking.deployed();
    const stakingAdd = await staking.address;
    console.log(stakingAdd);

})

})


