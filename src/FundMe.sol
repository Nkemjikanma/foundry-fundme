// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe_NotOwner();

contract FundMe {
    // Attach priceconverter function lib to all uint256
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5 * 1e18;

    // struct Funder {
    //     string funderName;
    //     address funderAddress;
    // }

    address[] private funders;
    mapping(address funder => uint256 amount) private addressToAmount;

    address public immutable i_owner;

    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Only contract owner can withdraw");
        if (msg.sender != i_owner) {
            revert FundMe_NotOwner();
        }
        _;
    }

    constructor(address priceFeed) {
        i_owner = msg.sender; // this is because the deployer of the contract is the sender and this gets called once the contract is deployed
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    // function to send money to our contract
    function fund() public payable {
        // User must have minimum amount

        // ensures that amount being sent is greater than 1eth
        // the require function also accepts a message
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "Not enough eth is being sent"); // 1ETH in wei = 1 * 10 ** 18 = 1000000000000000000

        // list of funders
        funders.push(msg.sender);

        // object to hold address to value sent
        addressToAmount[msg.sender] = addressToAmount[msg.sender] + msg.value;
    }

    // function to withdraw by owner
    function withdraw() public onlyOwner {
        // reset the mappings back to zero to show that we have withdrawn all the money and nothing is left.

        for (uint256 index = 0; index < funders.length; index++) {
            address funder = funders[index];
            addressToAmount[funder] = 0;
        }

        funders = new address[](0);

        //using transfer - auto reverts but throws error
        // msg.sender is of type address and should be converted to type payable
        // payable(msg.sender).transfer(address(this).balance);

        //using send - doesn't auto revert and returns bool
        // msg.sender is of type address and should be converted to type payable
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Sending failed");

        // using call -
        (bool callSuccess, /*bytes memory dataReturned*/ ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Sending failed");
    }

    function cheaperWithdraw() public onlyOwner {
        address[] memory _funders = funders;
        // mappings can't be in memory, sorry!
        for (uint256 funderIndex = 0; funderIndex < _funders.length; funderIndex++) {
            address funder = _funders[funderIndex];
            addressToAmount[funder] = 0;
        }

        _funders = new address[](0);
        // payable(msg.sender).transfer(address(this).balance);
        (bool success,) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    /**
     * Getter Functions
     */

    /**
     * @notice Gets the amount that an address has funded
     *  @param fundingAddress the address of the funder
     *  @return the amount funded
     */
    function getAddressToAmountFunded(address fundingAddress) public view returns (uint256) {
        return addressToAmount[fundingAddress];
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getFunder(uint256 index) public view returns (address) {
        return funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}
// Get funds from user
// Withdraw funds
// Set a minimum funding value in USD
