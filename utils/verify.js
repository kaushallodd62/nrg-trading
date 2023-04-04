const { run } = require("hardhat");

async function verify(contractAddress, args) {
    console.log("Verifying Contract...");
    try {
        run("verify:verify", {
            address: contractAddress,
            constructorArguments: args,
        });
    } catch (e) {
        if (e.message.toLowerCase().includes("already verified")) {
            console.error("Already Verified");
        } else {
            console.error(e);
        }
    }
}

module.exports = { verify };
