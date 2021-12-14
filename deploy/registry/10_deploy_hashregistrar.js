const { ethers } = require("hardhat");

const ethernal = require('hardhat-ethernal');

const namehash = require('eth-ens-namehash');
const sha3 = require('web3-utils').sha3;

module.exports = async ({getNamedAccounts, deployments, network}) => {
    const {deploy} = deployments;
    const {deployer, owner} = await getNamedAccounts();

    const ens = await ethers.getContract('ENSRegistry')

    await deploy('HashRegistar', {
        from: deployer, 
        args: [ens.address, 1639301531, 1639301981, 1639302001, owner],
        log: true
    })

}


module.exports.tags = ['name']
module.exports.dependencies = ['registry']