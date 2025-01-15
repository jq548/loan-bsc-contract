const hre = require("hardhat");

async function main() {
  const contractAddress = "0x2Af4B03E77ce77a4Faf8AE099694AB75c522148A";
  const LPToken = await hre.ethers.getContractFactory("LPToken");
  const ppToken = await LPToken.attach(contractAddress);

  const tx = await ppToken.transferOwnership("0xD2616032e562D70dc0CEc32dC710A0483e0AC900", { gasLimit: "0x1000000" });
  await tx.wait();

  console.log("setValue transaction hash:", tx.hash);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });