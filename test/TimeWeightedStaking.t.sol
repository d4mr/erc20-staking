// test/TimeWeightedStaking.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {TimeWeightedStaking} from "../src/TimeWeightedStaking.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract TimeWeightedStakingTest is Test {
    TimeWeightedStaking public staking;
    MockERC20 public token;

    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");

    function setUp() public {
        token = new MockERC20("Mock Token", "MOCK");

        // Deploy staking contract with 1% daily rewards
        staking = new TimeWeightedStaking(
            address(token),
            86400, // 1 day
            1, // 1% rewards
            100 // denominator for 1%
        );

        // Setup test users
        token.mint(user1, 1000e18);
        token.mint(user2, 1000e18);

        vm.startPrank(user1);
        token.approve(address(staking), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(staking), type(uint256).max);
        vm.stopPrank();
    }

    function test_Stake() public {
        vm.startPrank(user1);
        staking.stake(100e18);
        assertEq(token.balanceOf(address(staking)), 100e18);
        assertEq(token.balanceOf(user1), 900e18);

        (uint256 stakedAmount, , , uint256 pendingRewards) = staking
            .getStakeInfo(user1);
        assertEq(stakedAmount, 100e18);
        assertEq(pendingRewards, 0);
        vm.stopPrank();
    }

    function test_RewardCalculation() public {
        vm.startPrank(user1);
        staking.stake(100e18);

        // Fast forward 1 day
        vm.warp(block.timestamp + 86400);

        // Should have ~1% rewards
        uint256 rewards = staking.calculatePendingRewards(user1);
        assertApproxEqRel(rewards, 1e18, 0.01e18); // 1% with 1% tolerance
        vm.stopPrank();
    }

    function test_MultipleStakes() public {
        vm.startPrank(user1);

        // First stake of 50e18
        uint256 initialBalance = token.balanceOf(user1);
        staking.stake(50e18);

        // Fast forward 12 hours
        vm.warp(block.timestamp + 43200);

        // Second stake of 50e18, which will claim the first period's rewards (0.25e18)
        staking.stake(50e18);

        // Verify first period rewards were claimed
        assertApproxEqRel(
            token.balanceOf(user1),
            initialBalance - 100e18 + 0.25e18, // Initial - total staked + first period rewards
            0.01e18
        );

        // Fast forward another 12 hours
        vm.warp(block.timestamp + 43200);

        // Check pending rewards for the second period only
        // 100e18 staked for 12 hours = 0.5% rewards = 0.5e18
        uint256 pendingRewards = staking.calculatePendingRewards(user1);
        assertApproxEqRel(pendingRewards, 0.5e18, 0.01e18);

        vm.stopPrank();
    }

    function test_Withdraw() public {
        vm.startPrank(user1);
        staking.stake(100e18);

        // Fast forward 1 day
        vm.warp(block.timestamp + 86400);

        // Withdraw half
        staking.withdraw(50e18);

        // Check balances
        assertEq(token.balanceOf(address(staking)), 49e18);
        assertApproxEqRel(token.balanceOf(user1), 951e18, 0.01e18); // 900 + 50 + ~1 in rewards

        (uint256 stakedAmount, , , uint256 pendingRewards) = staking
            .getStakeInfo(user1);
        assertEq(stakedAmount, 50e18);
        assertEq(pendingRewards, 0); // Rewards should have been claimed during withdraw
        vm.stopPrank();
    }

    function test_RevertOnWithdrawTooMuch() public {
        vm.startPrank(user1);
        staking.stake(100e18);
        vm.expectRevert("Insufficient stake");
        staking.withdraw(150e18);
        vm.stopPrank();
    }
}
