// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    FundMe fundMe;

    function run() external returns (FundMe) {
        HelperConfig helperConfig = new HelperConfig();
        address ethUSDAddress = helperConfig.activeNetworkConfig();

        // everything after the broacast starts is a real transaction
        vm.startBroadcast();

        fundMe = new FundMe(ethUSDAddress);

        vm.stopBroadcast();
        return fundMe;
    }
}
