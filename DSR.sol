// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import { Dai } from "./StableCoins.sol";
import { SafeMath } from "./SafeMath.sol";

/**
 * Interface for Dai Savings Pot (Dai Savings Rate Contract)
 * Based on actual DSR contract at 0x197e90f9fad81970ba7976f33cbd77088e5d7cf7
 * Documentation can be found here: 
 * https://docs.makerdao.com/smart-contract-modules/rates-module/pot-detailed-documentation
 *
 * We have slightly simplified the interface for this problem.
 * You can use our Mock DaiPot for your solution, or use your own Mock, or use the actual DSR contract
 *
**/
interface DaiPot {
    /**
     * Get balance including interest in DAI
    **/
    function balance() external view returns (uint256);

    /**
     * @dev Calculate most recent chi value (multiplier for interest)
     * A user should always make sure that this has been called before calling the exit() function.
     * drip has to be called before a user joins and it is in their interest to call it again before they exit, 
     * but there isn't a set rule for how often drip is called.
     */
    function drip() external returns (uint256);

    /**
     * @dev use TransferFrom to deposit DAI into the pool
     */
    function join(uint256 amount) external;

    /**
     * @dev exit the pool, withdrawing amount in DAI
     * Always call drip() to update interest before exiting
     */
    function exit(uint256 amount) external;
}

/**
 * @title DaiPotMock
 * @dev Mock Dai Pot for testing
 *
 * Mock a contract similar to a DSR contract, with additional functions 
 * to simulate earning interest
 *
 * Note: this contract is untested and might require modifications
 */
contract DSRMock is DaiPot {
    using SafeMath for uint256;

    // multiplier to calculate interest
    // 18 decimals
    uint256 chi;

    // DAI ERC20 Token
    Dai dai;

    /**
     * @dev pass address of dai contract
     * @param daiAddress address of Dai contract
     */
    constructor(address daiAddress) public {
        dai = Dai(daiAddress);
        chi = 2;
    }

    /**
     * @dev Get balance including interest in DAI
     * @return pool balance in DAI
    **/
    function balance() override external view returns (uint256) {
        return dai.balanceOf(address(this));
    }

    /**
     * @dev Simulate interest by increasing chi value
     * @param by amount to increase chi value by
     */
    function increaseDripValue(uint256 by) external {
        chi = chi.add(by);
    }

    /**
     * @dev Calculate & return most recent chi value (multiplier for interest)
     * @return chi value
     */
    function drip() override external returns (uint256) {
        return chi;
    }

    /**
     * @dev use TransferFrom to deposit DAI into the pool
     * Must approve before calling this function
     * @param amount amount of DAI to deposit into pool
     */
    function join(uint256 amount) override external {
        dai.transferFrom(msg.sender, address(this), amount);
    }

    /**
     * @dev exit the pool, withdrawing amount in DAI
     * @param amount amount of DAI to withdraw from pool
     */
    function exit(uint256 amount) override external {
        dai.transfer(msg.sender, amount);
    }
}