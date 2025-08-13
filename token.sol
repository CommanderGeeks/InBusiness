// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IN BUSINESS Token ($BUSINESS)
 * @dev The Universal Business Network Token
 * 
 * Total Supply: 1,000,000,000 (Fixed, No Minting)
 * Network: Base (Ethereum L2)
 * 
 * A revolutionary cryptocurrency solving the $2.7 trillion global cash flow crisis
 * that causes 82% of business failures. Businesses allocate 5-10% of monthly revenue
 * to build collective financial resilience through network effects.
 */

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions. The owner account will be set to address(0) after
 * initial setup for true decentralization.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Main IN BUSINESS Token Contract
 */
contract InBusinessToken is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    // Token metrics for the network
    mapping(address => bool) public isBusinessAccount;
    mapping(address => uint256) public businessJoinedTimestamp;
    uint256 public totalBusinessAccounts;
    uint256 public totalMonthlyAllocation;
    
    uint256 private constant _totalSupply = 1_000_000_000 * 10**18; // 1 billion tokens
    string public constant name = "IN BUSINESS";
    string public constant symbol = "BUSINESS";
    uint8 public constant decimals = 18;
    
    // Network tracking events
    event BusinessJoined(address indexed business, uint256 timestamp);
    event MonthlyAllocation(address indexed business, uint256 amount);
    event NetworkMilestone(uint256 totalBusinesses, uint256 totalValue);
    
    // Anti-bot measures for launch
    bool public tradingEnabled = false;
    uint256 public maxTransactionAmount;
    uint256 public maxWalletAmount;
    mapping(address => bool) public isExcludedFromLimits;
    
    // Network statistics
    struct NetworkStats {
        uint256 totalBusinesses;
        uint256 monthlyVolume;
        uint256 totalValueLocked;
        uint256 averageAllocation;
        uint256 networkHealthScore;
    }
    
    NetworkStats public networkStats;
    
    constructor() {
        // Initial configuration
        maxTransactionAmount = _totalSupply * 10 / 1000; // 1% of total supply
        maxWalletAmount = _totalSupply * 20 / 1000; // 2% of total supply
        
        // Exclude owner and this contract from limits
        isExcludedFromLimits[owner()] = true;
        isExcludedFromLimits[address(this)] = true;
        
        // Mint entire supply to deployer for fair launch distribution
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
    
    /**
     * @dev Enable trading after liquidity is added
     */
    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already enabled");
        tradingEnabled = true;
    }
    
    /**
     * @dev Update transaction limits (only during launch phase)
     */
    function updateLimits(uint256 _maxTransaction, uint256 _maxWallet) external onlyOwner {
        require(_maxTransaction >= _totalSupply / 200, "Max transaction too low"); // Min 0.5%
        require(_maxWallet >= _totalSupply / 100, "Max wallet too low"); // Min 1%
        maxTransactionAmount = _maxTransaction;
        maxWalletAmount = _maxWallet;
    }
    
    /**
     * @dev Remove limits after launch phase for free market
     */
    function removeLimits() external onlyOwner {
        maxTransactionAmount = _totalSupply;
        maxWalletAmount = _totalSupply;
    }
    
    /**
     * @dev Register a business account in the network
     */
    function registerBusiness(address account) external {
        require(!isBusinessAccount[account], "Already registered");
        isBusinessAccount[account] = true;
        businessJoinedTimestamp[account] = block.timestamp;
        totalBusinessAccounts++;
        networkStats.totalBusinesses++;
        
        emit BusinessJoined(account, block.timestamp);
        
        // Milestone celebrations
        if (totalBusinessAccounts % 1000 == 0) {
            emit NetworkMilestone(totalBusinessAccounts, address(this).balance);
        }
    }
    
    /**
     * @dev Record monthly allocation from a business (called by automation)
     */
    function recordMonthlyAllocation(address business, uint256 amount) external {
        require(isBusinessAccount[business], "Not a registered business");
        totalMonthlyAllocation += amount;
        networkStats.monthlyVolume += amount;
        
        emit MonthlyAllocation(business, amount);
    }
    
    /**
     * @dev Calculate network health score (0-100)
     */
    function calculateNetworkHealth() public view returns (uint256) {
        if (totalBusinessAccounts == 0) return 0;
        
        uint256 businessScore = totalBusinessAccounts > 10000 ? 30 : (totalBusinessAccounts * 30) / 10000;
        uint256 volumeScore = totalMonthlyAllocation > 10000000 * 10**18 ? 40 : (totalMonthlyAllocation * 40) / (10000000 * 10**18);
        uint256 distributionScore = 30; // Placeholder for distribution analysis
        
        return businessScore + volumeScore + distributionScore;
    }
    
    /**
     * @dev Get comprehensive network statistics
     */
    function getNetworkStats() external view returns (
        uint256 businesses,
        uint256 monthlyVolume,
        uint256 avgAllocation,
        uint256 healthScore
    ) {
        businesses = totalBusinessAccounts;
        monthlyVolume = networkStats.monthlyVolume;
        avgAllocation = totalBusinessAccounts > 0 ? monthlyVolume / totalBusinessAccounts : 0;
        healthScore = calculateNetworkHealth();
    }
    
    /**
     * @dev Standard ERC20 Functions
     */
    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        
        _transfer(sender, recipient, amount);
        return true;
    }
    
    /**
     * @dev Internal transfer function with anti-bot protection
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from zero address");
        require(recipient != address(0), "ERC20: transfer to zero address");
        
        // Check trading status
        if (!isExcludedFromLimits[sender] && !isExcludedFromLimits[recipient]) {
            require(tradingEnabled, "Trading not yet enabled");
            
            // Anti-bot limits
            require(amount <= maxTransactionAmount, "Exceeds max transaction");
            
            if (recipient != owner()) {
                require(_balances[recipient] + amount <= maxWalletAmount, "Exceeds max wallet");
            }
        }
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        unchecked {
            _balances[sender] = senderBalance - amount;
            _balances[recipient] += amount;
        }
        
        emit Transfer(sender, recipient, amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from zero address");
        require(spender != address(0), "ERC20: approve to zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    /**
     * @dev Exclude accounts from limits (for DEX routers, etc.)
     */
    function excludeFromLimits(address account, bool excluded) external onlyOwner {
        isExcludedFromLimits[account] = excluded;
    }
    
    /**
     * @dev Batch exclude from limits for efficiency
     */
    function batchExcludeFromLimits(address[] calldata accounts, bool excluded) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isExcludedFromLimits[accounts[i]] = excluded;
        }
    }
    
    /**
     * @dev Emergency function to recover stuck tokens (not BUSINESS tokens)
     */
    function recoverToken(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(this), "Cannot recover BUSINESS tokens");
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
    
    /**
     * @dev Emergency function to recover stuck ETH
     */
    function recoverETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    /**
     * @dev Receive ETH for network treasury
     */
    receive() external payable {
        networkStats.totalValueLocked += msg.value;
    }
}