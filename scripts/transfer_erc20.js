const hre = require("hardhat");

async function main() {
  const contractAddress = "0xd851D918C4970F91453f5Cf50CD59e6f38aE6D5b";
  const LPToken = await hre.ethers.getContractFactory("LPToken");
  const ppToken = await LPToken.attach(contractAddress);

  // 100
  const tx = await ppToken.transfer("0x12dd188d6EeF13a55240067F9D5125859c2f00b2", "100000000000000000000", { gasLimit: "0x1000000" });
  await tx.wait();

  console.log("setValue transaction hash:", tx.hash);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });