require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.0",
  settings: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  },
  networks: {
    ssctest: {
      url: process.env.URL || "https://testnet-rpc.amstarscan.com",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [""],
    },
    bsctest: {
      url: process.env.URL || "https://bsc-testnet.public.blastapi.io",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [""],
    },
    bscmain: {
      url: process.env.URL || "https://bsc.publicnode.com",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [""],
    },
    ethtest: {
      url: process.env.URL || "https://eth-goerli.public.blastapi.io",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [""],
    },
    ethmain: {
      url: process.env.URL || "https://ethereum.publicnode.com",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [""],
    }
  },
  etherscan: {
    apiKey: {
      ssctest: process.env.BROWSER_API_KEY,
      bsctest: process.env.BROWSER_API_KEY,
      bscmain: process.env.BROWSER_API_KEY,
    },
    customChains: [
      {
        network: "ssctest",
        chainId: 1138,
        urls: {
          apiURL: "https://testnet.amstarscan.com/api",
          browserURL: "https://testnet.amstarscan.com/"
        }
      },
      {
        network: "bsctest",
        chainId: 97,
        urls: {
          apiURL: "https://api-testnet.bscscan.com/api",
          browserURL: "https://testnet.bscscan.com/"
        }
      },
      {
        network: "bscmain",
        chainId: 56,
        urls: {
          apiURL: "https://api.bscscan.com/api",
          browserURL: "https://bscscan.com/"
        }
      }
    ]
  }
};
