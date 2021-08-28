pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Pool {
  using SafeMath for uint256;

  uint256 constant PRECISION = 10**18;

  // Owner
  address private immutable owner;

  uint256 private totalDepositors;
  uint256 private totalRewards;
  uint256 private depositBalance;

  // Track amount and block number
  struct Reward {
    uint256 amount;
    uint256 depositorCount;
    uint256 contractBalance;
  }

  mapping(uint256 => Reward) private rewards;

  mapping(address => mapping(uint256 => uint256)) private deposits;

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
  event Withdraw(address from, uint256 amount);

  // Emmited when amount deposited into reward's pool
  event RewardsDeposited(address from, uint256 amount);

  // Deposit ETH into pool
  function deposit(uint256 amount) external payable {
    require(msg.value == amount, "Amount does not match value");

    if (deposits[msg.sender][0] == 0) {
      totalDepositors += 1;
    }

    deposits[msg.sender][totalRewards] += msg.value;

    depositBalance += msg.value;

    emit Deposit(msg.sender, msg.value);
  }

  // Withdraw deposit and rewards
  function withdraw() external {
    require(deposits[msg.sender][0] != 0, "User has nothing to withdraw");

    uint256 withdrawAmount;
    uint256 depositedAmount;

    for (uint256 i = 0; i <= totalRewards; i++) {
      withdrawAmount += deposits[msg.sender][i];

      if (rewards[i].contractBalance == 0) continue;

      depositedAmount += deposits[msg.sender][i];

      uint256 ratio = depositedAmount.mul(PRECISION).div(rewards[i].contractBalance);
      uint256 cut = ratio.mul(rewards[i].amount).div(PRECISION);

      withdrawAmount += cut;
      rewards[i].depositorCount -= 1;
      deposits[msg.sender][i] = 0;

      // TODO: If last withdrawal, add remainder to withdrawAmount
      if (rewards[i].depositorCount == 0) {
        delete rewards[i];
      }
    }

    require(withdrawAmount <= address(this).balance, "Not enough funds");

    emit Withdraw(msg.sender, withdrawAmount);

    totalDepositors -= 1;

    payable(msg.sender).transfer(withdrawAmount);
  }

  // Owner can deposit rewards
  function depositRewards(uint256 amount) external payable {
    require(msg.sender == owner, "Not owner of the contract");
    require(msg.value == amount, "Amount does not match value");
    require(totalDepositors > 0, "No depositors are available for rewards");

    rewards[totalRewards].amount = msg.value;
    rewards[totalRewards].depositorCount = totalDepositors;
    rewards[totalRewards].contractBalance = depositBalance;

    totalRewards += 1;

    emit RewardsDeposited(msg.sender, msg.value);
  }

  function getBalance() external view returns (uint256) {
    return address(this).balance;
  }

  function getReward(uint256 i) external view returns (Reward memory) {
    return rewards[i];
  }

  function getTotalRewards() external view returns (uint256) {
    return totalRewards;
  }

  function getMyBalance(uint256 i) external view returns (uint256) {
    return deposits[msg.sender][i];
  }
}
