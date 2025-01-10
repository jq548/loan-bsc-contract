// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Loan {

    struct loan {
        uint256 amount;
        uint256 stage;
        uint256 dayPerStage;
        uint256 loanRate;
        uint256 status; // 0 normal, 1 payed back, 2 cleard
        address loaner;
    }

    uint256 loanCount;
    mapping (uint256 => loan) loans;

    mapping (uint256 => address) public addresses; // 0 owner, 1 caller, 2 usdt contract, 3 lp contract

    // liquid
    uint256 totalLiquidAmount;
    mapping (address => uint256) liquidProviderAmount;
    mapping (address => uint256) liquidReward;

    modifier onlyOwner() {
        require(addresses[0] == msg.sender, "only owner");
        _;
    }

    modifier onlyCaller() {
        require(addresses[0] == msg.sender, "only caller");
        _;
    }

    event eventNewLoan(uint256 loanId, uint256 amount, uint256 stage, uint256 dayPerStage, uint256 loanRate, address loaner);
    event eventPayRate(uint256 loanId, uint256 rate, uint256 stage, address loaner);
    event evntPayBack(uint256 loanId, uint256 rate, uint256 amount, address loaner);
    event eventClear(uint256 loanId, uint256 amount, address loaner);

    constructor() {
        addresses[0] = msg.sender;
    }

    function initialize(
        address caller,
        address usdt,
        address lp) public onlyOwner() {
        addresses[1] = caller;
        addresses[2] = usdt;
        addresses[3] = lp;
    }

    function addNewLoan(uint256 amount, uint256 stage, uint256 dayPerStage, uint256 loanRate, address loaner) public onlyCaller() {

    }

    function payLoanRate(uint256 loanId) public {
        require(loans[loanId].loaner == msg.sender, "only loaner");
    }

    function payBack(uint256 loanId) public {
        require(loans[loanId].loaner == msg.sender, "only loaner");
    }

    function clear(uint256 loanId) public onlyCaller() {

    }

    function transferOwner(address owner) public onlyOwner() {
        addresses[0] = owner;
    }

    function transferCaller(address caller) public onlyOwner() {
        addresses[1] = caller;
    }

    function setUsdtContract(address usdt) public onlyOwner() {
        addresses[2] = usdt;
    }

    function setLpContract(address lp) public onlyOwner() {
        addresses[3] = lp;
    }

    function extractAllCoin() public onlyOwner() {

    }

    function maxExchangeLpUsdt(bool forward) public view returns (uint256) {
        return 0;
    }

    function exchangeLpUsdt(bool forward, uint256 amount) public {

    }

    function releaseAbleLiquidReward(address provider) public view returns (uint256) {
        return liquidReward[provider];
    }

    function releaseLiquidReward() public {

    }

    function increaseLiquidReward() public onlyCaller() {

    }

}