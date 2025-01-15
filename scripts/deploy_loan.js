const hre = require("hardhat");

async function deployLoan() {
  const LoanContract = await ethers.getContractFactory("Loan");
  console.log("Deploying LoanContract...");
  const loan = await hre.upgrades.deployProxy(LoanContract, []);
  sleep(6);
  console.log("LoanContract deployed to:", await loan.getAddress());
}

function sleep(n) {
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, n);
}


async function main() {
    await deployLoan();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });