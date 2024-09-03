require("@nomicfoundation/hardhat-toolbox");
const path = require("path");

module.exports = {
  solidity: {
    version: "0.8.26",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,  // Enable the viaIR flag
    },
  },
  paths: {
    sources: path.resolve(__dirname, "contracts"),
    cache: path.resolve(__dirname, "cache"),
    artifacts: path.resolve(__dirname, "artifacts"),
  },
  resolve: {
    alias: {
      "@openzeppelin/contracts": path.resolve(__dirname, "node_modules/@openzeppelin/contracts"),
    },
  },
};
