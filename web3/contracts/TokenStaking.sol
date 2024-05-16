// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Initializable.sol";
import "./IERC20.sol"

contract TokenStaking is Ownable, ReentrancyGuard, Initializable {
    struct User {
        uint256 stakeAmount;
        uint256 rewardAmount;
        uint256 lastStakeTime;
        uint256 lastRewardCalculationTime;
        uint256 reardsClaimedSoFar;
    }

    uint256 _minimumStakingAmount;
    uint256 _maxStakeTokenLimit;
    uint256 _stakeEndDate;
    uint256 _stakeStartDate;
    uint256 _totalStakedTokens;
    uint256 _totalUsers;
    uint256 _stakeDays;
    uint256 _earlyUnstakeFeePercentage;
    bool _isStakingPaused;

    address private _tokenAddress;
    uint256 _apyRate;
    uint256 public constant = PERCENTAGE_DENOMINATOR = 10000;
    uint256 public constant = APY_RATE_CHANGE_THRESHOLD  = 10;

    mapping(address => User) private Users;

    event Stake(address indexed user, uint256 amount);
    event UnStake(address indexed user, uint256 amount);
    event EarlyUnStakeFee(addresss indexed user, uint256 amount);
    event ClaimReward( address indexed user, uint256 amount);

    modifier whenTreasuryHasBalance(uint256 amount) {
        require(IERC20(_tokenAddress).balanceOf(address(this)) >= amount, "TokenStaking: insufficient funds in treasury");
        _;
    }

    function initalize(
        address owner_, 
        address tokenAddress_, 
        uint256 apyRate_,
        uint256 minimumStakingAmount_,
        uint256 maxStakeTokenLimit_,
        uint256 stakeStartDate_,
        uint256 stakeEndDate_,
        uint256 stakeDays_,
        uint256 _earlyUnstakeFeePercentage_
        ) public virtual initializer {
            __TokenStaking_init_unchained(
                owner_,
                tokenAddress_,
                apyRate_,
                minimumStakingAmount_,
                maxStakeTokenLimit_,
                stakeStartDate_,
                stakeEndDate_,
                stakeDays_,
                _earlyUnstakeFeePercentage_
            );
        }

    function __TokenStaking_init_unchained(
        address owner_,
        address tokenAddress_,
        address apyRate_,
        u
    )
}
