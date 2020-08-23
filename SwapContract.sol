// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import { Dai, TrueUSD } from "./StableCoins.sol";

/**
 * @dev Mock swap interface meant to simplify & mimick uniswap behavior
 */
interface SwapContract {
    function swapDAIforTUSD(uint256 amount) external;
    function swapTUSDforDAI(uint256 amount) external;
}

/**
 * @title SwapContractMock
 * @dev Mock swap contract meant to simplify & mimick uniswap behavior
 *
 * Note: this contract is untested and might require modifications
 */
contract SwapContractMock is SwapContract {
    Dai dai;
    TrueUSD tusd;

    constructor(address daiAddress, address tusdAddress) public {
        dai = Dai(daiAddress);
        tusd = TrueUSD(tusdAddress);
    }

    /**
     * @dev Swap DAI for TUSD 1:1 using transferFrom
     * @param amount amount of DAI to swap for TUSD
     */
    function swapDAIforTUSD(uint256 amount) override external {
        dai.transferFrom(msg.sender, address(this), amount);
        tusd.transfer(msg.sender, amount);
    }

    /**
     * @dev Swap TUSD for DAI 1:1 using transferFrom
     * @param amount amount of TUSD to swap for DAI
     */
    function swapTUSDforDAI(uint256 amount) override external {
        tusd.transferFrom(msg.sender, address(this), amount);
        dai.transfer(msg.sender, amount);
    }
}