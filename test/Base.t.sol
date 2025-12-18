// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Base
 * @notice Base test contract with common setup and utilities
 */
contract Base is Test {
    // ============ Constants ============

    uint256 constant INITIAL_BALANCE = 1_000_000e6; // 1M USDC
    uint256 constant PRECISION = 1e18;

    // ============ Setup ============

    function setUp() public virtual {
        // Override in child contracts
    }

    // ============ Helpers ============

    /**
     * @notice Mint tokens to an address (for testing)
     * @param token Token address
     * @param to Recipient address
     * @param amount Amount to mint
     */
    function _mint(address token, address to, uint256 amount) internal {
        vm.prank(to);
        // This assumes the token has a mint function or we're using a mock
        // In real tests, we'd use deal() or mock the token
    }

    /**
     * @notice Approve token spending
     * @param token Token address
     * @param owner Owner address
     * @param spender Spender address
     * @param amount Amount to approve
     */
    function _approve(address token, address owner, address spender, uint256 amount) internal {
        vm.prank(owner);
        IERC20(token).approve(spender, amount);
    }

    /**
     * @notice Transfer token
     * @param token Token address
     * @param from Sender address
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function _transfer(address token, address from, address to, uint256 amount) internal {
        vm.prank(from);
        IERC20(token).transfer(to, amount);
    }

    /**
     * @notice Assert two values are approximately equal
     * @param a First value
     * @param b Second value
     * @param tolerance Tolerance percentage (e.g., 100 = 1%)
     */
    function assertApproxEq(uint256 a, uint256 b, uint256 tolerance) internal pure {
        uint256 diff = a > b ? a - b : b - a;
        uint256 maxDiff = (b * tolerance) / 10000;
        require(diff <= maxDiff, "Values not approximately equal");
    }
}
