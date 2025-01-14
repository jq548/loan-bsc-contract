// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "./LP.sol";

contract Loan is Context {

    struct loan {
        uint256 amount;
        uint256 duration;
        uint256 start;
        uint256 status; // 0 normal, 1 payed back, 2 cleard
        address loaner;
    }

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

    event eventNewLoan(uint256 loanId, uint256 duration, uint256 start, uint256 amount, address loaner);
    event eventPayBack(uint256 loanId, uint256 amount, address loaner);
    event eventClear(uint256 loanId, uint256 amount, address loaner);
    event eventProviderIncrease(uint256 amount, address provider);
    event eventProviderRetrieve(uint256 amount, address provider);
    event eventIncreaseLiquidReward(uint256 amount, address provider);
    event eventReleaseLiquidReward(uint256 amount, address provider);

    function init(
        address owner,
        address caller,
        address usdt,
        address lp) public {
            require(owner == address(0));
            addresses[0] = owner;
            addresses[1] = caller;
            addresses[2] = usdt;
            addresses[3] = lp;
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

    function addNewLoan(uint256 id, uint256 amount, uint256 duration, address loaner) public onlyCaller() {
        uint256 current = block.timestamp;
        loan memory l = loan(
            amount,
            duration,
            current,
            0,
            loaner
        );
        loans[id] = l;
        emit eventNewLoan(id, duration, current, amount, loaner);
    }

    function payBack(uint256 loanId) public {
        require(loans[loanId].loaner == msg.sender, "only loaner");
        require(loans[loanId].status == 0, "not allowed status");
        IERC20 usdt  = IERC20(addresses[2]);
        require(usdt.transferFrom(msg.sender, address(this), loans[loanId].amount));
        loans[loanId].status = 1;
        emit eventPayBack(loanId, loans[loanId].amount, loans[loanId].loaner);
    }

    function maxExchangeLpUsdt(bool forward) public view returns (uint256) {
        if (forward) {
            return 1000000000000000000000000;
        } else {
            IERC20 usdt  = IERC20(addresses[2]);
            return usdt.balanceOf(address(this));
        }
    }

    function exchangeLpUsdt(bool forward, uint256 amount) public {
        require(amount < maxExchangeLpUsdt(forward), "too much");
        LPToken lp = LPToken(addresses[3]);
        IERC20 usdt  = IERC20(addresses[2]);
        if (forward) {
            lp.burnFrom(msg.sender, amount);
            require(usdt.transfer(msg.sender, amount));
        } else {
            lp.mint(msg.sender, amount);
            require(usdt.transferFrom(msg.sender, address(this), amount));
        }
    }

    function releaseAbleLiquidReward(address provider) public view returns (uint256) {
        return liquidReward[provider];
    }

    function releaseLiquidReward() public {
        uint256 amount = liquidReward[msg.sender];
        require(amount > 0, "no reward");
        IERC20 usdt  = IERC20(addresses[2]);
        usdt.transfer(msg.sender, amount);
        liquidReward[msg.sender] -= amount;
        emit eventReleaseLiquidReward(amount, msg.sender);
    }

    function increaseLiquidReward(uint256 amount, address provider) public onlyCaller() {
        require(amount > 0, "increase nothing");
        liquidReward[provider] += amount;
        emit eventIncreaseLiquidReward(amount, provider);
    }

    function provideUsdt(uint256 amount) public {
        IERC20 erc20Token = IERC20(addresses[2]);
        require(erc20Token.transferFrom(msg.sender, address(this), amount));
        totalLiquidAmount += amount;
        liquidProviderAmount[msg.sender] += amount;
        emit eventProviderIncrease(amount, msg.sender);
    }

    function retrieveUsdt() public {
        IERC20 erc20Token = IERC20(addresses[2]);
        uint256 amount = liquidProviderAmount[msg.sender];
        require(erc20Token.transfer(msg.sender, amount));
        liquidProviderAmount[msg.sender] = 0;
        totalLiquidAmount -= amount;
        emit eventProviderRetrieve(amount, msg.sender);
    }

    function clear(uint256 loanId) public onlyCaller() {
        require(loans[loanId].status == 0);
        require(loans[loanId].start + loans[loanId].duration > block.timestamp);
        loans[loanId].status = 2;
        emit eventClear(loanId, loans[loanId].amount, loans[loanId].loaner);
    }

    function extract(address token) public onlyOwner() {
        IERC20 erc20Token = IERC20(token);
        require(erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this))));
    }

}