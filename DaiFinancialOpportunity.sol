// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import { Dai, TrueUSD } from "./StableCoins.sol";
import { FinancialOpportunity } from "./FinancialOpportunity.sol";
import { DaiPot, DSRMock } from "./DSR.sol";
import { SwapContract, SwapContractMock } from "./SwapContract.sol";

/**
 * @title Dai Financial Opportunity
 * @dev Pool TUSD deposits to earn interest using DSR
 *
 * When a user wants to deposit TrueUSD** the contract will exchange 
 * the TUSD for Dai using Uniswap, and then deposit DAI into a DSR.
 *
 * When a user wants to redeem their stake for TrueUSD the contract will 
 * withdraw DAI from a DSR, then swap the DAI for TrueUSD using Uniswap.

 * Implement the 4 functions from FinancialOpportunity in a new contract: 
 * deposit(), redeem(), tokenValue(), and totalSupply(). 
 * 
 * Make sure to read the documentation in FinaicialOpportunity.sol carefully 
 * to make sure you understand the purpose of each of these functions. 
 *
 * Note: the contract mocks are untested and might require modifications!
 *
**/
contract DaiFinancialOpportunity is FinancialOpportunity {
    
    // TODO Implement your DSR Financial Opportunity here
    
    uint256 private total_yTUSD;
    uint256 public total_TUSD_Pooled;
    uint256 private token_value;
    mapping (address => uint256) public depositors;
    Dai dai;
    TrueUSD tusd;
    SwapContract swp;
    DSRMock dsrMock;

    
    constructor(address daiAddress, address tusdAddress, address swapContract, address dsrAddr) public {
        total_yTUSD = 0;
        token_value = 0;
        total_TUSD_Pooled = 0;
        dai = Dai(daiAddress);
        tusd = TrueUSD(tusdAddress);
        swp = SwapContract(swapContract);
        dsrMock = DSRMock(dsrAddr);
    }
    
     /**
     * @dev Returns total supply of yTUSD in this contract
     *
     * @return total supply of yTUSD in this contract
    **/
    function totalSupply() public view override returns (uint256) {
        return total_yTUSD;
    }

    /**
     * @dev Exchange rate between TUSD and yTUSD
     *
     * tokenValue should never decrease
     *
     * @return TUSD / yTUSD price ratio
     */
    function tokenValue() public view override returns(uint256) {
        return token_value;
    }

    /**
     * @dev deposits TrueUSD and returns yTUSD minted
     *
     * We can think of deposit as a minting function which
     * will increase totalSupply of yTUSD based on the deposit
     *
     * @param from account to transferFrom
     * @param amount amount in TUSD to deposit
     * @return yTUSD minted from this deposit
     */
    function deposit(address from, uint amount) override public returns(uint) {
        // check if the depositor has enough TUSD or Not
        require(tusd.balanceOf(from) >= amount, "Not enough TUSD balance");
        // transfer the user's TUSD to this contract
        tusd.transferFrom(from, address(this), amount);
        //approve the swap contract to use TUSD
        tusd.allowance(address(this), address(swp));
        tusd.approve(address(swp), amount);
        // add to total TUSD Pooled & convert to DAI
        total_TUSD_Pooled += amount;
        swp.swapTUSDforDAI(amount);
        // calculate the interest amount that wi;; generated after this transaction
        uint256 interestAmount =  (dsrMock.drip() * total_TUSD_Pooled)/100; 
        //approve the DSRMock to use the DAI & Join the DSRMock
        dai.allowance(address(this), address(dsrMock));
        dai.approve(address(dsrMock), amount);
        dsrMock.join(amount);
        // calculate no. of yTUSD to be generated - Amount/100 yTUSD will be minted for all transactions
        total_yTUSD += amount/100;
        // calculate interest considering 1:1 ratio and calculate token_value 
        token_value = interestAmount/total_yTUSD;
        // add user to depositor list
        depositors[msg.sender] = amount;
        // return yTUSD
        return amount/10;
    }

    /**
     * @dev Redeem yTUSD for TUSD and withdraw to account
     *
     * This function should use tokenValue to calculate
     * how much TUSD is owed. This function should burn yTUSD
     * after redemption
     *
     * This function must return value in TUSD
     *
     * @param to account to transfer TUSD for
     * @param amount amount in TUSD to withdraw from finOp
     * @return TUSD amount returned from this transaction
     */
    function redeem(address to, uint amount) public override returns(uint) {
        // check if enough TUSD has been deposited
        require(depositors[msg.sender] >= amount, 'Not enough TUSD deposited');
        // reduce depositor amount
        depositors[msg.sender] -= amount;
        // calculate total TUSD owed and burn yTUSD
        uint256 totalTUSDOwed = amount/100 * tokenValue();
        total_yTUSD -= amount/100;
        // total TUSD to return (amount request + TUSD owed) : I had a doubt about this though i went wwith this
        // mint the interest amount in DAI for the user
        dai._mint(address(dsrMock), totalTUSDOwed);
        // exit from DSRMock and withdraw the ampunt + interestAmount
        dsrMock.exit(amount + totalTUSDOwed);
        // approve the swapContract to use the DAI to swap to TUSD
        dai.allowance(address(this), address(swp));
        dai.approve(address(swp), amount + totalTUSDOwed);
        // mint the owed TUSD for swapContract for swapping
        tusd._mint(address(swp), totalTUSDOwed);
        swp.swapDAIforTUSD(amount + totalTUSDOwed);
        
        // transfer the TUSD + Profit to the TO address
        tusd.transfer(to, amount + totalTUSDOwed);
        
        // reduce total TUSD pooled 
        total_TUSD_Pooled = total_TUSD_Pooled - amount;
        
        // get interest rate and calculate new interest amount
        uint256 interestAmount = (dsrMock.drip() * total_TUSD_Pooled)/100;
        
        // new token value for yTUSD
        if(total_yTUSD == 0) {
            token_value = 0;
        } else {
            token_value = interestAmount/total_yTUSD;
        }
        // return totalTUSD 
        return amount + totalTUSDOwed;
    }
}

