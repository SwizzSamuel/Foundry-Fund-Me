// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/Fundme.sol";

contract FundFundMe is Script {

    uint256 constant SEND_VALUE = 5 ether;

    function fundFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe fundMe = new FundMe(payable(mostRecentlyDeployed));
        fundMe.fund{value: SEND_VALUE}();
        vm.stopBroadcast();
    }
    
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        fundFundMe(mostRecentlyDeployed);
    }
}

contract WithdrawFundMe is Script {

    function withdrawFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe fundMe = new FundMe(payable(mostRecentlyDeployed));
        fundMe.withdraw();
        vm.stopBroadcast();
    }
    
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        withdrawFundMe(mostRecentlyDeployed);
    }
}