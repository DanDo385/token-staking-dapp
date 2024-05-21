// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

contract TokenStaking is Ownable, ReentrancyGuard {
    struct User {
        uint256 stakeAmount;
        uint256 rewardAmount;
        uint256 lastStakeTime;
        uint256 lastRewardCalculationTime;
        uint256 rewardsClaimedSoFar;
    }

    uint256 private _minimumStakingAmount;
    uint256 private _maxStakeTokenLimit;
    uint256 private _stakeEndDate;
    uint256 private _stakeStartDate;
    uint256 private _totalStakedTokens;
    uint256 private _totalUsers;
    uint256 private _stakeDays;
    uint256 private _earlyUnstakeFeePercentage;
    bool private _isStakingPaused;

    address private _tokenAddress;
    uint256 private _apyRate;
    bool private _initialized;

    mapping(address => User) private _users;

    event Stake(address indexed user, uint256 amount);
    event UnStake(address indexed user, uint256 amount);
    event EarlyUnStakeFee(address indexed user, uint256 amount);
    event ClaimReward(address indexed user, uint256 amount);

    modifier whenTreasuryHasBalance(uint256 amount) {
        require(IERC20(_tokenAddress).balanceOf(address(this)) >= amount, "TokenStaking: insufficient funds in treasury");
        _;
    }

    function initialize(
        address owner_, 
        address tokenAddress_, 
        uint256 apyRate_,
        uint256 minimumStakingAmount_,
        uint256 maxStakeTokenLimit_,
        uint256 stakeStartDate_,
        uint256 stakeEndDate_,
        uint256 stakeDays_,
        uint256 earlyUnstakeFeePercentage_
    ) public {
        require(!_initialized, "TokenStaking: already initialized");
        _initialized = true;

        Ownable.transferOwnership(owner_);
        _tokenAddress = tokenAddress_;
        _apyRate = apyRate_;
        _minimumStakingAmount = minimumStakingAmount_;
        _maxStakeTokenLimit = maxStakeTokenLimit_;
        _stakeStartDate = stakeStartDate_;
        _stakeEndDate = stakeEndDate_;
        _stakeDays = stakeDays_ * 1 days;
        _earlyUnstakeFeePercentage = earlyUnstakeFeePercentage_;
    }
        
    // View Methods and Other Functions below remain unchanged
    // Ensure to remove onlyInitializing modifier and adjust accordingly
}

        
        // View Methods

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

        // Owner Methods

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
            emit Stake(user_, _amount);

        function unstake(uint256 _amount) external nonReentrant whenTreasuryHasBalance (_amount) {
            address user = msg.sender;

            require(_amount != 0, "TokenStaking: amount should be greater than zero");
            require(this.isStakeHolder(user), "TokenStaking: not a stakeholder");
            require(_users[user].stakeAmount >= _amount, "TokenStaking: not enough stake to unstake");

            _calculateRewards(user);

            uint256 feeEarlyUnstake;

            if(getCurrentTime() <= _users[user].lastStakeTime + _stakeDays) {
                feeEarlyUnstake = ((_amount * _earlyUnstakeFeePercentage) / PERCENTAGE_DENOMINATOR);
                emit EarlyUnStakeFee(user, feeEarlyUnstake);
            }

            uint256 amountToUnstake = _amount - feeEarlyUnstake;

            _users[user].stakeAmount = -= _amount;

            _totalStakedTokens -= _amount;

            if(_users[user].stakeAmount == 0) {
                _totalUsers -= 1;
            }        

            require(IERC20(_tokenAddress).transfer(user, amountToUnstake), "TokenStaking: failed to transfer");
            emit Unstake(user, _amount);
        }

        function claimReward() external nonReentrant whenTreasuryHasBalance(_users[msg.sender].rewardAmount) {
            _calculateRewards(msg.sender);
            uint256 rewardAmount = _users[msg.sender].rewardAmount;

            require(rewardAmount > 0, "TokenStaking: no reward to be claimed");

            require(IERC20(_tokenAddress).transfer(msg.sender, rewardAmount), "TokenStaking: failed to transfer");

            _users[msg.sender].rewardAmount = 0;
            _users[msg.sender].rewardsClaimedSoFar += rewardAmount;

            emit ClaimReward(msg.sender, rewardAmount); 
        }

        // Interal Functions

        function _calculateRewards(address _user) private {
            (uint256 userReward, uint256 currentTime) = _getUserEstimatedRewards(_user);

            _users[_user].rewardAmount += userReward;
            _users[_user].lastRewardCalculationTime = currentTime;
        }

        function _getUserEstimatedRewards(address _user) private view returns (uint256, uint256) {
            uint256 userReward;
            uint256 userTimeStamp = _users[_user].lastRewardCalculationTime;

            uint256 currentTime = getCurrentTime();

            if(currentTime > _users[_user].lastStakeTime + _stakeDays) {
                currentTime = _users[_user].lastStakeTime + _stakeDays;
            }

            uint256 totalStakeTime = currentTime - userTimeStamp;

            userReward += ((totalStakeTime * _users[_user].stakeAmount * _apyRate) * 365 days) / PERCENTAGE_DENOMINATOR;
        }

        function getCurrentTime() internal view virtual returns (uint256) {
            return block.timeStamp;
        }
}