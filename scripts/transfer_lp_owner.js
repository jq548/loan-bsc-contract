const hre = require("hardhat");

async function main() {
  const contractAddress = process.env.LP;
  const LPToken = await hre.ethers.getContractFactory("DINARToken");
  const ppToken = await LPToken.attach(contractAddress);

  const tx = await ppToken.transferOwnership(process.env.LOAN, { gasLimit: "0x1000000" });
  await tx.wait();

  console.log("setValue transaction hash:", tx.hash);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });