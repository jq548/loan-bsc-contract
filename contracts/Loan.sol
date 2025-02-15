// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "./DINAR.sol";

contract Loan is Context {

    struct loan {
        uint256 loanAmount;
        uint256 duration;
        uint256 start;
        uint256 status; // 0 normal, 1 payed back, 2 cleared, 3 finish cleared
        address loaner;
        uint256 releaseAmount;
        uint256 interestAmount;
        string contractNumber;
        string aleoAddress;
        uint256 aleoAmount;
        uint256 aleoPrice;
    }

    struct liquidProvide {
        uint256 amount;
        uint256 duration;
        uint256 start;
        uint256 status; // 0 normal, 1 redeemed
        address provider;
        string contractNumber;
    }

    mapping (uint256 => loan) public loans;

    // 0 owner
    // 1 caller
    // 2 usdt contract
    // 3 dinar contract
    mapping (uint256 => address) public addresses; 

    // 0 total Liquid Amount
    // 1 total Liquid Record Count
    // 2 withraw reward fee
    // 3 min provide
    // 4 max provide
    // 5 timestamp of last create loan (today at 00:00:00)
    // 6 count of loans were created today
    // 7 timestamp of last create liquidity (today at 00:00:00)
    // 8 count of liquidities were created today
    mapping (uint256 => uint256 ) public params; 

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

    event eventNewLoan(
        uint256 loanId, 
        uint256 duration, 
        uint256 start, 
        uint256 loanAmount, 
        address loaner, 
        uint256 releaseAmount, 
        uint256 interestAmount, 
        string contractNumber,
        string aleoAddress,
        uint256 aleoAmount,
        uint256 aleoPrice);
    event eventPayBack(
        uint256 loanId, 
        uint256 amount, 
        address loaner);
    event eventClear(
        uint256 loanId, 
        uint256 amount, 
        address loaner);
    event eventFinishClear(
        uint256 id,
        uint256 loanAmount,
        uint256 clearAmount);
    event eventProviderAdd(
        uint256 id, 
        uint256 duration, 
        uint256 start, 
        uint256 amount, 
        address provider,
        string contractNumber);
    event eventProviderRedeem(
        uint256 id, 
        uint256 amount, 
        address provider, 
        uint256 fee);
    event eventIncreaseLiquidReward(
        uint256 amount, 
        address provider);
    event eventIncreaseLiquidRewardBath(
        uint256[] ids, 
        uint256[] amounts, 
        address[] providers);
    event eventReleaseLiquidReward(
        uint256 amount, 
        address provider, 
        uint256 fee);
    event eventExchangeDinarToUsdt(
        bool forward, 
        uint256 amount, 
        address caller);

    function init(
        address owner,
        address caller,
        address usdt,
        address dinar) public {
            require(addresses[0] == address(0));
            addresses[0] = owner;
            addresses[1] = caller;
            addresses[2] = usdt;
            addresses[3] = dinar;
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

    function setDinarContract(address dinar) public onlyOwner() {
        addresses[3] = dinar;
    }

    function setParams(uint256 key, uint256 value) public onlyCaller() {
        require(key == 2 || key == 3 || key == 4, "only allow 2/3/4");
        params[key] = value;
    }

    function addNewLoan(
        uint256 id,
        uint256 amount, 
        uint256 duration, 
        address loaner, 
        uint256 interestAmount, 
        string calldata aleoAddress,
        uint256 aleoAmount,
        uint256 aleoPrice) public onlyCaller() {
        require(loans[id].loaner == address(0), "loan already exist");
        uint256 current = block.timestamp;
        uint256 releaseAmount = amount - interestAmount;
        string memory contractNumber = updateNextContractNumber(1);
        loans[id] = loan(
            amount,
            duration,
            current,
            0,
            loaner,
            releaseAmount,
            interestAmount,
            contractNumber,
            aleoAddress,
            aleoAmount,
            aleoPrice
        );
        DINARToken(addresses[3]).mint(loaner, amount);
        emit eventNewLoan(id, duration, current, amount, loaner, releaseAmount, interestAmount, contractNumber, aleoAddress, aleoAmount, aleoPrice);
    }

    function payBack(uint256 loanId) public {
        require(loans[loanId].loaner == msg.sender, "only loaner");
        require(loans[loanId].status == 0, "not allowed status");
        DINARToken(addresses[3]).burnFrom(msg.sender, loans[loanId].loanAmount);
        loans[loanId].status = 1;
        emit eventPayBack(loanId, loans[loanId].loanAmount, loans[loanId].loaner);
    }

    function maxExchangeDinarUsdt(bool forward) public view returns (uint256) {
        if (forward) {
            return IERC20(addresses[3]).balanceOf(address(this));
        } else {
            return IERC20(addresses[2]).balanceOf(address(this));
        }
    }

    function exchangeDinarUsdt(bool forward, uint256 amount) public {
        require(amount < maxExchangeDinarUsdt(forward), "too much");
        if (forward) {
            require(IERC20(addresses[3]).transferFrom(msg.sender, address(this), amount));
            require(IERC20(addresses[2]).transfer(msg.sender, amount));
        } else {
            require(IERC20(addresses[2]).transferFrom(msg.sender, address(this), amount));
            require(IERC20(addresses[3]).transfer(msg.sender, amount));
        }
        emit eventExchangeDinarToUsdt(forward, amount, msg.sender);
    }

    function releaseAbleLiquidReward(address provider) public view returns (uint256) {
        return liquidReward[provider];
    }

    function releaseLiquidReward() public {
        uint256 amount = liquidReward[msg.sender];
        require(amount > 0, "no reward");
        uint256 fee = params[2];
        IERC20(addresses[2]).transfer(msg.sender, amount - fee);
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
        require(IERC20(addresses[2]).transferFrom(msg.sender, address(this), amount));
        uint256 newId = params[1];
        uint256 current = block.timestamp;
        string memory contractNumber = updateNextContractNumber(2);
        liquidProvide memory newlp = liquidProvide(
            amount,
            duration,
            current,
            0,
            msg.sender,
            contractNumber
        );
        liquidProvides[newId] = newlp;
        params[1] = newId + 1;
        params[0] += amount;
        emit eventProviderAdd(current, duration, current, amount, msg.sender, contractNumber);
    }

    function retrieveUsdt(uint256 provideId) public {
        uint256 amount = liquidProvides[provideId].amount;
        uint256 releaseAmount = amount;
        if (liquidProvides[provideId].start + liquidProvides[provideId].duration < block.timestamp) {
            releaseAmount = amount * 97 / 100;
        }
        require(IERC20(addresses[2]).transfer(msg.sender, releaseAmount));
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

    function finishClear(uint256 loanId, uint256 clearAmount) public onlyCaller() {
        require(loans[loanId].status == 2);
        DINARToken(addresses[3]).burn(clearAmount);
        loans[loanId].status = 3;
        emit eventFinishClear(loanId, loans[loanId].loanAmount, clearAmount);
    }

    function extract(address token) public onlyOwner() {
        require(IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this))));
    }

    // 1 loan
    // 2 provide liquidity
    function updateNextContractNumber(uint256 type_) internal returns(string memory) {
        require(type_ == 1 || type_ == 2, "nor allowed");
        uint256 beginOfToday = block.timestamp - block.timestamp % 86400;
        if (type_ == 1) {
            if (beginOfToday == params[5]) {
                params[6] = params[6] + 1;
            } else {
                params[5] = beginOfToday;
                params[6] = 1;
            }
            string memory extra0 = "";
            if (params[6] < 10) {
                extra0 = "0000";
            } else if (params[6] >= 10 && params[6] < 100) {
                extra0 = "000";
            } else if (params[6] >= 100 && params[6] < 1000) {
                extra0 = "00";
            } else if (params[6] >= 1000 && params[6] < 10000) {
                extra0 = "0";
            }
            return concat(concat(concat(concat("L", uintToString(params[5])), extra0), uintToString(params[6])), "P2P");
        } else if (type_ == 2) {
            if (beginOfToday == params[7]) {
                params[8] = params[8] + 1;
            } else {
                params[7] = beginOfToday;
                params[6] = 1;
            }
            string memory extra0 = "";
            if (params[8] < 10) {
                extra0 = "0000";
            } else if (params[8] >= 10 && params[8] < 100) {
                extra0 = "000";
            } else if (params[8] >= 100 && params[8] < 1000) {
                extra0 = "00";
            } else if (params[8] >= 1000 && params[8] < 10000) {
                extra0 = "0";
            }
            return concat(concat(concat(concat("LP", uintToString(params[7])), extra0), uintToString(params[8])), "P2P");
        }
        return "";
    }

    function uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function concat(string memory a, string memory b) internal pure returns (string memory) {
        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);
        string memory result = new string(ba.length + bb.length);
        bytes memory br = bytes(result);

        uint k = 0;
        for (uint i = 0; i < ba.length; i++) br[k++] = ba[i];
        for (uint i = 0; i < bb.length; i++) br[k++] = bb[i];

        return string(br);
    }

}