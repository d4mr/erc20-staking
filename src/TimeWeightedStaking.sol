// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "solady/utils/ReentrancyGuard.sol";

contract TimeWeightedStaking is ReentrancyGuard {
    using SafeTransferLib for address;

    address public immutable stakingToken;
    string public constant version = "1.0.0";

    uint256 public immutable timeUnit;
    uint256 public immutable rewardRatioNumerator;
    uint256 public immutable rewardRatioDenominator;

    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        uint256 lastClaimTime;
    }

    mapping(address => StakeInfo) public stakes;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);

    constructor(
        address _stakingToken,
        uint256 _timeUnit,
        uint256 _rewardRatioNumerator,
        uint256 _rewardRatioDenominator
    ) {
        require(_stakingToken != address(0), "Invalid token address");
        require(_timeUnit > 0, "Time unit must be positive");
        require(_rewardRatioDenominator > 0, "Denominator must be positive");

        stakingToken = _stakingToken;
        timeUnit = _timeUnit;
        rewardRatioNumerator = _rewardRatioNumerator;
        rewardRatioDenominator = _rewardRatioDenominator;
    }

    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot stake 0");

        StakeInfo storage userStake = stakes[msg.sender];

        // Claim any pending rewards before updating stake
        uint256 rewards = calculatePendingRewards(msg.sender);
        if (rewards > 0) {
            stakingToken.safeTransfer(msg.sender, rewards);
            emit RewardsClaimed(msg.sender, rewards);
        }

        // Transfer tokens to contract
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        // Update stake info
        if (userStake.amount == 0) {
            userStake.amount = amount;
            userStake.startTime = block.timestamp;
            userStake.lastClaimTime = block.timestamp;
        } else {
            userStake.amount += amount;
            userStake.lastClaimTime = block.timestamp;
        }

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot withdraw 0");

        StakeInfo storage userStake = stakes[msg.sender];
        require(userStake.amount >= amount, "Insufficient stake");

        // Claim rewards before withdrawal
        uint256 rewards = calculatePendingRewards(msg.sender);
        if (rewards > 0) {
            stakingToken.safeTransfer(msg.sender, rewards);
            emit RewardsClaimed(msg.sender, rewards);
        }

        // Update stake info before transfer
        userStake.amount -= amount;
        userStake.lastClaimTime = block.timestamp;

        // Transfer tokens back to user
        stakingToken.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function claimRewards() external nonReentrant {
        StakeInfo storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No stake found");

        uint256 rewards = calculatePendingRewards(msg.sender);
        require(rewards > 0, "No rewards to claim");

        userStake.lastClaimTime = block.timestamp;
        stakingToken.safeTransfer(msg.sender, rewards);
        emit RewardsClaimed(msg.sender, rewards);
    }

    function calculatePendingRewards(
        address user
    ) public view returns (uint256) {
        StakeInfo memory userStake = stakes[user];
        if (userStake.amount == 0) return 0;

        uint256 stakingDuration = block.timestamp - userStake.lastClaimTime;

        // Scale up the calculation to maintain precision
        // amount * duration * rewardRatioNumerator * 1e18 / (rewardRatioDenominator * timeUnit)
        uint256 reward = (((userStake.amount * stakingDuration) / timeUnit) *
            rewardRatioNumerator) / rewardRatioDenominator;

        return reward;
    }

    function getStakeInfo(
        address user
    )
        external
        view
        returns (
            uint256 stakedAmount,
            uint256 stakingStartTime,
            uint256 lastRewardClaimTime,
            uint256 pendingRewards
        )
    {
        StakeInfo memory userStake = stakes[user];
        return (
            userStake.amount,
            userStake.startTime,
            userStake.lastClaimTime,
            calculatePendingRewards(user)
        );
    }
}
