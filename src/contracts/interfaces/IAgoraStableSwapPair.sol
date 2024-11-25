// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IAgoraStableSwapPair {
    struct InitializeParams {
        address token0;
        address token1;
        uint256 token0PurchaseFee;
        uint256 token1PurchaseFee;
        address initialFeeSetter;
        address initialTokenReceiver;
        address initialAdminAddress;
    }

    error AddressIsNotRole(string role);
    error AmountInMaxExceeded(string message, uint256 provided, uint256 maximum);
    error AmountOutInsufficient(string message, uint256 provided, uint256 minimum);
    error DeadlinePassed();
    error InsufficientLiquidity();
    error InvalidAmount(string message, uint256 provided, uint256 maximum);
    error InvalidInitialization();
    error InvalidPath();
    error InvalidSwapAmounts(string message);
    error InvalidTokenAddress(address token);
    error NoTokensReceived();
    error NotInitializing();
    error RoleNameTooLong();
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);
    error SafeERC20FailedOperation(address token);

    event AddTokens(address indexed tokenAddress, address from, uint256 amount);
    event ConfigurePrice(uint256 basePrice, uint256 annualizedInterestRate);
    event Initialized(uint64 version);
    event RemoveTokens(address indexed tokenAddress, uint256 amount);
    event RoleAssigned(string indexed role, address indexed address_);
    event RoleRevoked(string indexed role, address indexed address_);
    event SetApprovedSwapper(address indexed approvedSwapper, bool isApproved);
    event SetPaused(bool isPaused);
    event SetTokenPurchaseFee(address indexed token, uint256 tokenPurchaseFee);
    event SetTokenReceiver(address indexed tokenReceiver);

    function ADMIN_ROLE() external view returns (string memory);
    function AGORA_ACCESS_CONTROL_STORAGE_SLOT() external view returns (bytes32);
    function AGORA_COMPOUNDING_ORACLE_STORAGE_SLOT() external view returns (bytes32);
    function AGORA_STABLE_SWAP_STORAGE_SLOT() external view returns (bytes32);
    function AGORA_STABLE_SWAP_TRANSIENT_LOCK_SLOT() external view returns (bytes32);
    function APPROVED_SWAPPER() external view returns (string memory);
    function FEE_SETTER_ROLE() external view returns (string memory);
    function PAUSER_ROLE() external view returns (string memory);
    function PRECISION() external view returns (uint256);
    function PRICE_SETTER_ROLE() external view returns (string memory);
    function TOKEN_REMOVER_ROLE() external view returns (string memory);
    function WHITELISTER_ROLE() external view returns (string memory);
    function _initializeAgoraCompoundingOracle() external;
    function addTokens(address _tokenAddress, uint256 _amount) external;
    function assignRole(string memory _role, address _newAddress, bool _addRole) external;
    function configurePrice(uint256 _basePrice, uint256 _annualizedInterestRate) external;
    function getAllRoles() external view returns (string[] memory _roles);
    function getAmountsIn(
        address _empty,
        uint256 _amountOut,
        address[] memory _path
    ) external view returns (uint256[] memory _amounts);
    function getAmountsOut(
        address _empty,
        uint256 _amountIn,
        address[] memory _path
    ) external view returns (uint256[] memory _amounts);
    function getCompoundingPrice(
        uint256 _lastUpdated,
        uint256 _currentTimestamp,
        uint256 _interestRate,
        uint256 _basePrice
    ) external pure returns (uint256 _currentPrice);
    function getPrice() external view returns (uint256 _currentPrice);
    function getRoleMembers(string memory _role) external view returns (address[] memory _members);
    function hasRole(string memory _role, address _address) external view returns (bool);
    function initialize(InitializeParams memory _params) external;
    function isPaused() external view returns (bool);
    function lastBlock() external view returns (uint256);
    function oracleAddress() external view returns (address);
    function removeTokens(address _tokenAddress, uint256 _amount) external;
    function reserve0() external view returns (uint256);
    function reserve1() external view returns (uint256);
    function setApprovedSwapper(address _approvedSwapper, bool _isApproved) external;
    function setPaused(bool _isPaused) external;
    function setTokenPurchaseFee(address _token, uint256 _tokenPurchaseFee) external;
    function setTokenReceiver(address _tokenReceiver) external;
    function swap(uint256 _amount0Out, uint256 _amount1Out, address _to, bytes memory _data) external;
    function swapExactTokensForTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path,
        address _to,
        uint256 _deadline
    ) external;
    function swapTokensForExactTokens(
        uint256 _amountOut,
        uint256 _amountInMax,
        address[] memory _path,
        address _to,
        uint256 _deadline
    ) external;
    function sync() external;
    function token0() external view returns (address);
    function token0OverToken1Price() external view returns (uint256);
    function token0PurchaseFee() external view returns (uint256);
    function token1() external view returns (address);
    function token1PurchaseFee() external view returns (uint256);
}
