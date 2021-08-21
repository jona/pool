pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Pool {
  using SafeMath for uint256;

  uint256 constant PRECISION = 10**18;

  // Owner
  address private immutable owner;

  // Total depositors
  uint256 private totalDepositors;

  // Balances
  mapping(address => uint256) private balances;

  // Depositor addresses
  mapping(uint256 => address) private depositorAddresses;

  // Rewards
  mapping(uint256 => uint256) private rewards;

  // Constructor
  constructor() {
    // Assign owner
    owner = msg.sender;

    // Initialize total depositor count
    totalDepositors = 0;
  }

  // Emmited when amount deposited into pool
  event Deposit(address from, uint256 amount);

  // Emmited when amount withdrawn from pool
  event Withdraw(address from, uint256);

  // Emmited when amount deposited into reward's pool
  event RewardsDeposited(address from, uint256);

  // Deposit ETH into pool
  function deposit(uint256 amount) public payable {
    require(msg.value == amount, "Amount does not match value");

    balances[msg.sender] = balances[msg.sender].add(amount);
    depositorAddresses[totalDepositors] = msg.sender;

    totalDepositors += 1;

    emit Deposit(msg.sender, msg.value);
  }

  // Deposit all ETH associated with msg.sender from pool
  function withdraw() public {
    require(balances[msg.sender] > 0, "No pool exists for this sender");
    require(address(this).balance >= balances[msg.sender], "Not enough funds");

    uint256 withdrawAmount = balances[msg.sender];

    // Prevent re-entrancy attacks
    balances[msg.sender] = 0;

    payable(msg.sender).transfer(withdrawAmount);

    totalDepositors -= 1;

    emit Withdraw(msg.sender, withdrawAmount);
  }

  // Owner can deposit rewards
  function depositRewards(uint256 amount) public payable {
    require(msg.sender == owner, "Not owner of the contract");
    require(msg.value == amount, "Amount does not match value");
    require(totalDepositors > 0, "No depositors are available for rewards");

    // NOTE: When it gets withdrawn, there's a remainder left
    // because it's not precise
    uint256 shareAmount = msg.value.mul(PRECISION).div(totalDepositors).div(PRECISION);

    // NOTE: This seems inefficient. There's a solidity design pattern
    // I'm missing here that would help solve for this inefficiency.
    for (uint256 i = 0; i < totalDepositors; i++) {
      balances[depositorAddresses[i]] = balances[depositorAddresses[i]].add(shareAmount);
    }

    emit RewardsDeposited(msg.sender, msg.value);
  }

  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function getMyBalance() public view returns (uint256) {
    return balances[msg.sender];
  }
}
