const { ethers } = require("hardhat");
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
const ZERO_HASH = "0x0000000000000000000000000000000000000000000000000000000000000000"
const sha3 = require('web3-utils').sha3;
const namehash = require('eth-ens-namehash');
module.exports = async ({getNamedAccounts, deployments, network}) => {
    const {deploy} = deployments;
    const {deployer, owner} = await getNamedAccounts();

    const ens = await ethers.getContract('ENSRegistry')

    await deploy('OwnedResolver', {
        from: deployer, 
        args: [],
        log: true
    })
}

module.exports.tags = ['owned-resolver'];
module.exports.dependencies = ['registry']