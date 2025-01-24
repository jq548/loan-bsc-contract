// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "./LP.sol";

contract Loan is Context {

    struct loan {
        uint256 loanAmount;
        uint256 duration;
        uint256 start;
        uint256 status; // 0 normal, 1 payed back, 2 cleard
        address loaner;
        uint256 releaseAmount;
        uint256 interestAmount;
    }

    struct liquidProvide {
        uint256 amount;
        uint256 duration;
        uint256 start;
        uint256 status; // 0 normal, 1 redeemed
        address provider;
    }

    mapping (uint256 => loan) public loans;

    mapping (uint256 => address) public addresses; // 0 owner, 1 caller, 2 usdt contract, 3 lp contract

    mapping (uint256 => uint256 ) public params; // 0 total Liquid Amount, 1 total Liquid Record Count, 2 withraw reward fee, 3 min provide, 4 max provide

    mapping (uint256 => liquidProvide) public liquidProvides;
    mapping (address => uint256) public liquidReward;

    modifier onlyOwner() {
        require(addresses[0] == msg.sender, "only owner");
        _;
    }

    modifier onlyCaller() {
        require(addresses[0] == msg.sender, "only caller");
        _;
    }

    event eventNewLoan(uint256 loanId, uint256 duration, uint256 start, uint256 loanAmount, address loaner, uint256 releaseAmount, uint256 interestAmount);
    event eventPayBack(uint256 loanId, uint256 amount, address loaner);
    event eventClear(uint256 loanId, uint256 amount, address loaner);
    event eventProviderAdd(uint256 id, uint256 duration, uint256 start, uint256 amount, address provider);
    event eventProviderRedeem(uint256 id, uint256 amount, address provider, uint256 fee);
    event eventIncreaseLiquidReward(uint256 amount, address provider);
    event eventIncreaseLiquidRewardBath(uint256[] ids, uint256[] amounts, address[] providers);
    event eventReleaseLiquidReward(uint256 amount, address provider, uint256 fee);
    event eventExchangeLpToUsdt(bool forward, uint256 amount, address caller);

    function init(
        address owner,
        address caller,
        address usdt,
        address lp) public {
            require(addresses[0] == address(0));
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

    function setParams(uint256 key, uint256 value) public onlyCaller() {
        require(key == 2 || key == 3 || key == 4, "only allow 2/3/4");
        params[key] = value;
    }

    function addNewLoan(uint256 id, uint256 amount, uint256 duration, address loaner, uint256 interestAmount) public onlyCaller() {
        require(loans[id].loaner == address(0), "loan already exist");
        LPToken lp  = LPToken(addresses[3]);
        uint256 current = block.timestamp;
        uint256 releaseAmount = amount - interestAmount;
        loan memory l = loan(
            amount,
            duration,
            current,
            0,
            loaner,
            releaseAmount,
            interestAmount
        );
        loans[id] = l;
        lp.mint(msg.sender, amount);
        emit eventNewLoan(id, duration, current, amount, loaner, releaseAmount, interestAmount);
    }

    function payBack(uint256 loanId) public {
        require(loans[loanId].loaner == msg.sender, "only loaner");
        require(loans[loanId].status == 0, "not allowed status");
        IERC20 usdt  = IERC20(addresses[2]);
        require(usdt.transferFrom(msg.sender, address(this), loans[loanId].loanAmount));
        loans[loanId].status = 1;
        emit eventPayBack(loanId, loans[loanId].loanAmount, loans[loanId].loaner);
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
        emit eventExchangeLpToUsdt(forward, amount, msg.sender);
    }

    function releaseAbleLiquidReward(address provider) public view returns (uint256) {
        return liquidReward[provider];
    }

    function releaseLiquidReward() public {
        uint256 amount = liquidReward[msg.sender];
        require(amount > 0, "no reward");
        uint256 fee = params[2];
        IERC20 usdt  = IERC20(addresses[2]);
        usdt.transfer(msg.sender, amount - fee);
        liquidReward[msg.sender] -= amount;
        emit eventReleaseLiquidReward(amount, msg.sender, fee);
    }

    function increaseLiquidReward(uint256 amount, address provider) public onlyCaller() {
        require(amount > 0, "increase nothing");
        liquidReward[provider] += amount;
        emit eventIncreaseLiquidReward(amount, provider);
    }
    function increaseLiquidRewardBatch(uint256[] memory ids, uint256[] memory amounts, address[] memory providers) public onlyCaller() {
        require(amounts.length == providers.length, "increase nothing");
        for (uint256 i=0; i<amounts.length; i++) {
            liquidReward[providers[i]] += amounts[i];
        }
        emit eventIncreaseLiquidRewardBath(ids, amounts, providers);
    }

    function provideUsdt(uint256 amount, uint256 duration) public {
        require(amount >= params[3] && amount <= params[4], "exceed limit");
        IERC20 erc20Token = IERC20(addresses[2]);
        require(erc20Token.transferFrom(msg.sender, address(this), amount));
        uint256 newId = params[1];
        uint256 current = block.timestamp;
        liquidProvide memory newlp = liquidProvide(
            amount,
            duration,
            current,
            0,
            msg.sender
        );
        liquidProvides[newId] = newlp;
        params[1] = newId + 1;
        params[0] += amount;
        emit eventProviderAdd(current, duration, current, amount, msg.sender);
    }

    function retrieveUsdt(uint256 provideId) public {
        IERC20 erc20Token = IERC20(addresses[2]);
        uint256 amount = liquidProvides[provideId].amount;
        uint256 releaseAmount = amount;
        if (liquidProvides[provideId].start + liquidProvides[provideId].duration < block.timestamp) {
            releaseAmount = amount * 97 / 100;
        }
        require(erc20Token.transfer(msg.sender, releaseAmount));
        liquidProvides[provideId].status = 1;
        params[0] -= amount;
        emit eventProviderRedeem(provideId, amount, msg.sender, amount - releaseAmount);
    }

    function clear(uint256 loanId) public onlyCaller() {
        require(loans[loanId].status == 0);
        require(loans[loanId].start + loans[loanId].duration > block.timestamp);
        loans[loanId].status = 2;
        emit eventClear(loanId, loans[loanId].loanAmount, loans[loanId].loaner);
    }

    function extract(address token) public onlyOwner() {
        IERC20 erc20Token = IERC20(token);
        require(erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this))));
    }

}