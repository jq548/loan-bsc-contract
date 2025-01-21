const hre = require("hardhat");

async function main() {
  const contractAddress = "0xD856fEc774FA5E7CA8561DE9ef852cb0D94AFE77";
  const LPToken = await hre.ethers.getContractFactory("LPToken");
  const ppToken = await LPToken.attach(contractAddress);

  const tx = await ppToken.transferOwnership("0xe1354798516b08D65160CA5CB2C409b166699013", { gasLimit: "0x1000000" });
  await tx.wait();

  console.log("setValue transaction hash:", tx.hash);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });