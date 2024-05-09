// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/Fundme.sol";
import {DeployFundMe} from "../../script/Fundme.s.sol";

contract FundmeTest is Test{

    FundMe public fundme;

    address USER = makeAddr("USER");
    uint256 constant SEND_VALUE = 5e18;
    uint256 constant STARTING_BALANCE = 10e18;
    uint256 constant GAS_PRICE = 1;


    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundme = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

     modifier funded() {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();
        _;
    }


    function testMinimumIsFive() public {
        uint256 min = fundme.MINIMUM_USD();
        assertEq(min, 5 * 1e18);
    }

    function testOnlyOwner() public {
        assertEq(fundme.getOwner(), address(fundme));
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundme.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundme.fund();
    }

    function testFundUpdatesFundDataStructure() public funded{
        uint256 amount = fundme.getAmountFundedToAddress(USER);
        assertEq(amount, 5e18);
    }

    function testAddFunderToFunderList() public funded {
        address funder = fundme.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnercanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundme.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // ARRANGE
        uint256 startingBalance = fundme.getOwner().balance;
        uint256 startingFund = address(fundme).balance;

        // ACT
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundme.getOwner());
        fundme.withdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasEnd - gasStart) * GAS_PRICE;

        console.log("gas used: ", gasUsed);

        // ASSERT
        uint256 endingBalance = fundme.getOwner().balance;
        uint256 endingFund = address(fundme).balance;
        assertEq(endingBalance, startingBalance + startingFund);
        assertEq(endingFund, 0);
    }

    function testWithdrawFromMultipleFunders() public {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;

        for(uint160 funderIndex = startingFunderIndex; funderIndex < numberOfFunders; funderIndex++) {
           hoax(address(funderIndex), SEND_VALUE);

            fundme.fund{value: SEND_VALUE}();
        }

        uint256 startingBalance = fundme.getOwner().balance;
        uint startingFund = address(fundme).balance;

        vm.startPrank(fundme.getOwner());
        fundme.withdraw();
        vm.stopPrank();

        uint256 endingBalance = fundme.getOwner().balance;
        uint endingFund = address(fundme).balance;
        assertEq(endingBalance, startingBalance + startingFund);
        assertEq(endingFund, 0);
    }


    function testCheaperWithdrawFromMultipleFunders() public {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;

        for(uint160 funderIndex = startingFunderIndex; funderIndex < numberOfFunders; funderIndex++) {
           hoax(address(funderIndex), SEND_VALUE);

            fundme.fund{value: SEND_VALUE}();
        }

        uint256 startingBalance = fundme.getOwner().balance;
        uint startingFund = address(fundme).balance;

        vm.startPrank(fundme.getOwner());
        fundme.cheaperWithdraw();
        vm.stopPrank();

        uint256 endingBalance = fundme.getOwner().balance;
        uint endingFund = address(fundme).balance;
        assertEq(endingBalance, startingBalance + startingFund);
        assertEq(endingFund, 0);
    }
}