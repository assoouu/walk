const HotelBooking = artifacts.require("HotelBooking");

module.exports = async function(deployer) {
    await deployer.deploy(HotelBooking);
    const instance = await HotelBooking.deployed();
    await instance.addRoom("Deluxe Room", web3.utils.toWei("0.5", "ether"));
    await instance.addRoom("Standard Room", web3.utils.toWei("0.3", "ether"));
};
