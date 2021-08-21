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

  // Track amount and block number
  struct Depositor {
    uint256 balance;
    uint256 firstDepositAt;
  }

  // Depositors
  mapping(address => Depositor) private depositors;

  // Total Rewards
  uint256 private totalRewards;

  // Track amount and block number
  struct Reward {
    uint256 amount;
    uint256 depositedAt;
  }

  // Rewards
  mapping(uint256 => Reward) private rewards;

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

    if (depositors[msg.sender].balance == 0) {
      depositors[msg.sender].firstDepositAt = block.number;
    }

    depositors[msg.sender].balance = depositors[msg.sender].balance.add(amount);

    totalDepositors += 1;

    emit Deposit(msg.sender, msg.value);
  }

  // Deposit all ETH associated with msg.sender from pool
  function withdraw() public {
    require(depositors[msg.sender].balance > 0, "No pool exists for this sender");

    uint256 withdrawAmount = depositors[msg.sender].balance;

    // NOTE: Once all rewards are taken for a specific Reward,
    // we need to remove it from storage somehow.
    // How do we know if the last depositor for a given rewards
    // has withdrawn their deposit + reward?
    for (uint256 i = 0; i < totalRewards; i++) {
      if (rewards[i].depositedAt >= depositors[msg.sender].firstDepositAt) {
        withdrawAmount += rewards[i].amount;
      }
    }

    require(withdrawAmount <= address(this).balance, "Not enough funds");

    // Prevent re-entrancy attacks
    delete depositors[msg.sender];

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

    rewards[totalRewards].amount = shareAmount;
    rewards[totalRewards].depositedAt = block.number;
    totalRewards += 1;

    emit RewardsDeposited(msg.sender, msg.value);
  }

  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function getMyBalance() public view returns (uint256) {
    return depositors[msg.sender].balance;
  }
}
