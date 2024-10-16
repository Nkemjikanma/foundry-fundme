// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// console is a library for logging

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol"; // import the script to deploy the contract

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant MINIMUM_USD = 10e18;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();

        fundMe = deployFundMe.run();
        vm.deal(USER, 10 ether);
    } // need to set up the test contract

    // function testMinimumDollarisFive() public {
    //     assertEq(fundMe.MINIMUM_USD(), 5 * 1e18);
    // }

    function testOwnerIsSender() public {
        console.log(msg.sender);
        console.log(address(this));
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 priceFeedVersion = fundMe.getPriceFeed().version();
        console.log(priceFeedVersion);
        assertEq(priceFeedVersion, 4);

        // try priceFeedVersion.getVersion() returns (uint256 version) {}
    }

    // this test expects the contract to fail since not enough ETH
    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund(); // sends 0ETH
    }

    modifier funder() {
        vm.prank(USER);
        fundMe.fund{value: MINIMUM_USD}();
        _;
    }

    function testFundUpdatesFundedData() public {
        vm.prank(USER); // the tx will be sent by user
        fundMe.fund{value: MINIMUM_USD}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, MINIMUM_USD);
    }

    function testAddFunderToArrayOfFunder() public {
        vm.prank(USER);
        fundMe.fund{value: MINIMUM_USD}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funder {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funder {
        // arrange, act, assert
        // arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // act
        uint256 gasAtStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 gasAtEnd = gasleft();

        uint256 gasUsed = (gasAtStart - gasAtEnd) * tx.gasprice;
        console.log(gasUsed);

        // assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funder {
        uint160 numberOfFunders = 10; // if you want to use numbers to generate addresses, it has to be uint160
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), MINIMUM_USD);

            fundMe.fund{value: MINIMUM_USD}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assertEq(address(fundMe).balance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, fundMe.getOwner().balance);
    }

    function testWithdrawFromMultipleFundersCheaper() public funder {
        uint160 numberOfFunders = 10; // if you want to use numbers to generate addresses, it has to be uint160
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), MINIMUM_USD);

            fundMe.fund{value: MINIMUM_USD}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        assertEq(address(fundMe).balance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, fundMe.getOwner().balance);
    }
}
