// script/Deploy.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {TimeWeightedStaking} from "../src/TimeWeightedStaking.sol";

contract DeployTimeWeightedStaking is Script {
    function run() public returns (TimeWeightedStaking) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy with example parameters (adjust as needed):
        // 1% daily rewards (rewardRatio = 1/100)
        // timeUnit = 1 day (86400 seconds)
        TimeWeightedStaking staking = new TimeWeightedStaking(
            tokenAddress, // staking token address
            1, // timeUnit (1 day in seconds)
            1, // rewardRatioNumerator
            100 // rewardRatioDenominator
        );

        vm.stopBroadcast();
        return staking;
    }
}
