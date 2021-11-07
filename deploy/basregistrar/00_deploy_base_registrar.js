const { ethers } = require("hardhat");
const ZERO_HASH = "0x0000000000000000000000000000000000000000000000000000000000000000";
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

const ethernal = require('hardhat-ethernal');

const namehash = require('eth-ens-namehash');
const sha3 = require('web3-utils').sha3;

module.exports = async ({getNamedAccounts, deployments, network}) => {
    const {deploy} = deployments;
    const {deployer, owner} = await getNamedAccounts();

    const ens = await ethers.getContract('ENSRegistry')

    await deploy('BaseRegistrarImplementation', {
        from: deployer, 
        args: [ens.address, namehash.hash('avax')],
        log: true
    })

    const base = await ethers.getContract('BaseRegistrarImplementation');

    const ownedResolver = await ethers.getContract('OwnedResolver')


    const transactions = []
    transactions.push(await base.addController(owner, {from: deployer}))
    transactions.push(await ens.setSubnodeOwner(ZERO_HASH, sha3('avax'), base.address))
    transactions.push(await ens.setSubnodeRecord(ZERO_HASH, sha3('avax'), base.address, ownedResolver.address, 0))
    transactions.push(await base.register(sha3('resolver'), owner, 31536000, {from: deployer}))
    console.log(`Waiting on ${transactions.length} transactions setting base registrar`);
    await Promise.all(transactions.map((tx) => tx.wait()));
}


module.exports.tags = ['baseregistrar'];
module.exports.dependencies = ['registry', 'owned-resolver']