const { ethers, upgrades } = require('hardhat');

async function upgrade(oldLinearVesting) {
    const LoanContract = await ethers.getContractFactory("Loan");
    const loan = await upgrades.upgradeProxy(oldLinearVesting, LoanContract);
    return loan;
}

async function main() {
    loan = await upgrade("0xe1354798516b08D65160CA5CB2C409b166699013");

    console.log("address: ", await loan.getAddress());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
