// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from 'forge-std/Script.sol';
import {HelperConfig} from './HelperConfig.s.sol';
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from '../test/unit/mocks/LinkToken.sol';
import {DevOpsTools} from '../lib/foundry-devops/src/DevOpsTools.sol';


contract CreateSubscription is Script {

    function CreateSubscriptionUsingConfig() public returns(uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinatorV2, , , , ,uint256 deployerKey) = helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinatorV2, deployerKey);
    }

    function createSubscription(address vrfCoordinatorV2, uint256 deployerKey) public returns(uint64) {
        vm.startBroadcast(deployerKey);
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinatorV2).createSubscription();
        vm.stopBroadcast();
        console.log("Your subscription id is", subId);
        return subId;
    }

    function run() external returns (uint64) {
        return CreateSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUND = 3 ether;

    function fundSubscriptionUsingConfig() public {
           HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, ,uint64 subId, , address link, uint256 deployerKey) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinator, subId, link, deployerKey);
    }

    function fundSubscription(address vrfCoordinator, uint64 subId, address link, uint256 deployerKey) public {
        console.log("funding subscription by id ==>", subId);
        console.log("using vrf coordinator", vrfCoordinator);
        console.log("on ChainId", block.chainid);

        if(block.chainid == 31337) {
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subId, FUND_AMOUND);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(deployerKey);
            LinkToken(link).transferAndCall(vrfCoordinator, FUND_AMOUND, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {

    function addConsumer(address raffle, address vrfCoordinator, uint64 subId, uint256 deployerKey) public {
        console.log("raf",raffle);
        console.log("vrf coordiantor",vrfCoordinator);
        console.log("block id id",block.chainid);
        
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, raffle);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , uint64 subId, , , uint256 deployerKey) = helperConfig
        .activeNetworkConfig();
        addConsumer(raffle, vrfCoordinator, subId, deployerKey);

    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(raffle);
    }
}