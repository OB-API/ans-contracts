const { ethers } = require("hardhat");

const ethernal = require('hardhat-ethernal');

const namehash = require('eth-ens-namehash');
const sha3 = require('web3-utils').sha3;

module.exports = async ({getNamedAccounts, deployments, network}) => {
    const {deploy} = deployments;
    const {deployer, owner} = await getNamedAccounts();

    const ens = await ethers.getContract('ENSRegistry')

    await deploy('HashRegistrar', {
        from: deployer, 
        args: [ens.address, 1639301531],
        log: true
    })

}


module.exports.tags = ['name']
module.exports.dependencies = ['registry']