async function getDSO() {
    const [DSO] = await hre.ethers.getSigners();
    return DSO;
}

async function getProsumers() {
    const prosumers = (await hre.ethers.getSigners()).slice(1, 6);
    return prosumers;
}

async function getConsumers() {
    const consumers = (await hre.ethers.getSigners()).slice(6, 11);
    return consumers;
}

module.exports = {
    getDSO,
    getProsumers,
    getConsumers,
};
