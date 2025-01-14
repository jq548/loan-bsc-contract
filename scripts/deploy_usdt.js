  


  async function main() {
    const UsdtContract = await ethers.getContractFactory("USDT");
    console.log("Deploying USDT...");
    const usdt = await UsdtContract.deploy("10000000000000000000000");

    sleep(6);
    console.log("USDT deployed to:", await usdt.getAddress());
  }

  function sleep(n) {
    Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, n);
  }
  

main().then().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});