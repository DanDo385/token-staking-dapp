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
    event EarlyUnStakeFee(address indexed user, uint256 amount);
    event ClaimReward(address indexed user, uint256 amount);

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
        uint256 earlyUnstakeFeePercentage_
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
                earlyUnstakeFeePercentage_
            );
        }

    function __TokenStaking_init_unchained(
        address owner_,
        address tokenAddress_,
        uint256 apyRate_,
        uint256 minimumStakingAmount_,
        uint256 maxStakeTokenLimit_,
        uint256 stakeStartDate_
        uint256 stakeEndtDate_,
        uint256 stakeDays_,
        uint256 earlyUnstakeFeePercentage_
    ) internal onlyInitializing {
        require(apyRate_ <= 10000, "TokenStaking: apyRate should be less then 10000");
        require(stakeDays_ > 0, "TokenStaking: stake days must be greater than zero");
        require(tokenAddress_ != address(0), "TokenStaking: token address cannot be zero address");
        require(stakeStartDate_ < stakeEndDate, "TokenStaking: start date must be less then end date");

        _transferOwnership(owner_);
        _tokenAddress = tokenAddress_;
        _apyRate = apyRate_;
        _minimumStakingAmount = minimumStakingAmount_;
        _maxStakeTokenLimit = maxStakeTokenLimit_;
        _stakeStartDate = stakeStartDate_;
        _stakeEndDate = stakeEndDate_;
        _stakeDays = 1 * stakeDays_ * 1 days;
        _earlyUnstakeFeePercentage = earlyUnstakeFeePercentage_;
    }
        
        /* View Methods */

        function getMinimumStakingAmount() external view returns (uint256) {
            return _minimumStakingAmount;
        }

        function getMaxStakingTokenLimit() external view returns (uint256) {
            return _maxStakeTokenLimit;
        }

        function getStateStartDate() external view returns (uint256) {
            return _stakeStartDate;
        }

        function getStateEndDate() external view returns (uint256) {
            return _stakeEndDate;
        }

        function getTotalUsers() external view returns (uint256) {
            return _totalUsers;
        }

        function getStakeDays() external view returns (uint256) {
            return _stakeDays;
        }

        function getEarlyUnstakeFeePercentage() external view returns (uint256) {
            return _earlyUnstakeFeePercentage;
        }

        function getStakingStatus() external view returns (bool) {
            return _isStakingPaused;
        }

        function getAPY() external view retruns (uint256) {
            return _apyRate;
        }

        function getUserEstimatedRewards() external view returns (uint256) {
            (uint amount, ) = _getUserEstimatedRewards(msg.sender);
            return _users[msg.sender].rewardAmount + amount;
        }

        function getWithdrawableAmount() external view returns (uint256) {
            return IERC20(_tokenAddress).balanceOf(address(this)) - _totalStakedTokens;
        }

        function getUser(address userAddress) external view returns (User memory) {
            return _users[userAddress];
        }

        function isStakeHolder(address _user) external view returns (bool) {
            return _users[_user].stakeAmount != 0;
        }

        // Owner Method

        function updateMinimumStakingAmount(uint256 amount) external onlyOwner {
            _minimumStakingAmount = newAmount;
        }

        function updateMaximumStakingAmount(uint256 newAmount) external onlyOwner {
            _maxStakeTokenLimit = newAmount;
        }

        function updateEarlyUnstkaeFeePercentage(uint256 newPercentage) external onlyOwner {
            _earlyUnstakeFeePercentage = newPercentage;
        }

        function stakeForUser(uint256 amount, address user) external onlyOwner nonReentrant {
            _stakeTokens(amountUser);
        }

        function toggleStakingStatus() external onlyOwner {
            _isStakingPaused = !_isStakingPaused;
        }

        function withdraw(uint256 amount) external onlyOwner nonReentrant {
            require(this.getWithdrawableAmount() >= amount, "TokenStaking: not enough withdrawable tokens");
            EIRC20(_tokenAddress).tranfer(msg.sender, amount);
        }
       
        //User Methods

        function stake(uint256 _amount) external nonReentrant {
            _stakeTokens(_amount, msg.sender);
        }

        function _stakeTokens(uint256 _amount, address user_) private {
            require(!_isStakingPaused, "TokenStaking: staking is paused");

            uint256 currentTime = getCurrentTime();
            require(currentTime > _stakeStartEndDate, "TokenStaking: staking not started yet");
            require(currentTime < _stakeEndDate, "TokenStaking: staing ended");
            require(_totalStakedTokens + _amount <= _maxStakeTokenLimit, "TokenStaking: max staking token limit reached");
            require(_amount > 0, "TokenStaking: stake amount must be greater than zero");
            require(_amount >= _minimumStakingAmount, "TokenStaking: stake amount must be greater than minimum amount allowed");

            if (users[user_].stakeAmount != 0) {
                _calculateRewards(user_);
            } else {
                _users[user_].lastRewardCalculationTime = currentTime;
                _totalUsers += 1;
            }
        }

        _users[user_].stakeAmount += _amount;
        _users[user_].lastStakeTime = currentTime;

        _totalStakedTokens += _amount;

        require(
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount),
            "TokenStaking: failed to transfer tokens");
        );   
        emit Stake(user_, _amount);

        
}
