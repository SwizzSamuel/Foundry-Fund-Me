// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5 * 1e18;
    address[] private s_funders;
    address private immutable i_owner;
    mapping(address funder => uint256 amountFunded) private s_addressToAmountFunded;

    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
        i_owner = msg.sender;
    }

    modifier onlyOwner {
        // require(msg.sender == i_owner, "Not authorized");
        if(msg.sender != i_owner) {revert NotOwner(); }
        _;
    }

    function fund() public payable {
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "Didnt send enough ETH");
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function cheaperWithdraw() public onlyOwner{
        uint256 fundersLength = s_funders.length;
        for(uint256 funderIndex = 0; funderIndex < fundersLength; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call Failed");
    }

    function withdraw() public onlyOwner{
        for(uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        // payable(msg.sender).transfer(address(this).balance);
        
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send Failed");

        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call Failed");
    }

    receive() external payable { 
        fund();
    }

    fallback() external payable {
        fund();
    }

    function getAmountFundedToAddress(address funder) external view returns(uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getFunder(uint256 index) external view returns(address) {
        return s_funders[index];
    }

    function getVersion() public view returns(uint256) {
        return s_priceFeed.version();
    }

    function getFunders() public view returns(address[] memory) {
        return s_funders;
    }

    function getOwner() public view returns(address) {
        return i_owner;
    }


}