const hre = require("hardhat");

async function main() {
  const contractAddress = process.env.LOAN;
  const LoanContract = await hre.ethers.getContractFactory("Loan");
  const loanContract = await LoanContract.attach(contractAddress);

  const tx = await loanContract.init(process.env.OWNER, process.env.CALLER, process.env.USDT, process.env.LP, { gasLimit: "0x1000000" });
  await tx.wait();

  console.log("setValue transaction hash:", tx.hash);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });