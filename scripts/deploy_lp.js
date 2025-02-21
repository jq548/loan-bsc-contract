  
  async function main() {
    const LPToken = await ethers.getContractFactory("DINARToken");
    console.log("Deploying LPToken...");
    const lp = await LPToken.deploy("1000000000000000000000000");
    sleep(6);
    console.log("LPToken deployed to:", await lp.getAddress());
  }

  function sleep(n) {
    Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, n);
  }

main().then().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});