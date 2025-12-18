// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IProtocolAdapter} from "../../src/interfaces/IProtocolAdapter.sol";

/**
 * @title ProtocolAdapterMock
 * @notice Mock protocol adapter for testing
 */
contract ProtocolAdapterMock is IProtocolAdapter {
    using SafeERC20 for IERC20;

    IERC20 public usdc;
    uint256 public balance_;
    uint256 public apy = 500; // 5% APY

    constructor(address _usdc) {
        usdc = IERC20(_usdc);
    }

    function deposit(uint256 amount) external override returns (uint256 received) {
        usdc.safeTransferFrom(msg.sender, address(this), amount);
        balance_ += amount;
        return amount;
    }

    function withdraw(uint256 amount) external override returns (uint256 received) {
        require(balance_ >= amount, "Insufficient balance");
        balance_ -= amount;
        usdc.safeTransfer(msg.sender, amount);
        return amount;
    }

    function balance() external view override returns (uint256) {
        return balance_;
    }

    function getAPY() external view override returns (uint256) {
        return apy;
    }

    function getYieldAsset() external view override returns (address) {
        return address(usdc);
    }

    // Test helpers
    function setAPY(uint256 _apy) external {
        apy = _apy;
    }

    function setBalance(uint256 _balance) external {
        balance_ = _balance;
    }
}
