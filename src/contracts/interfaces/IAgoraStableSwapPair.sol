// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IAgoraStableSwapPair {
    struct InitializeParams {
        address token0;
        uint8 token0Decimals;
        address token1;
        uint8 token1Decimals;
        uint256 token0PurchaseFee;
        uint256 token1PurchaseFee;
        address initialFeeSetter;
        address initialTokenReceiver;
        address initialAdminAddress;
    }

    struct Version {
        uint256 major;
        uint256 minor;
        uint256 patch;
    }

    error AddressIsNotRole(string role);
    error AnnualizedInterestRateOutOfBounds();
    error BasePriceOutOfBounds();
    error DeadlinePassed();
    error ExcessiveInputAmount();
    error InsufficientInputAmount();
    error InsufficientLiquidity();
    error InsufficientOutputAmount();
    error InvalidAmount();
    error InvalidInitialization();
    error InvalidPath();
    error InvalidSwapAmounts();
    error InvalidToken0PurchaseFee();
    error InvalidToken1PurchaseFee();
    error InvalidTokenAddress(address token);
    error MinAnnualizedInterestRateGreaterThanMax();
    error MinBasePriceGreaterThanMaxBasePrice();
    error NotInitializing();
    error PairIsPaused();
    error ReentrancyGuardReentrantCall();
    error RoleNameTooLong();
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);
    error SafeERC20FailedOperation(address token);

    event AddTokens(address indexed tokenAddress, address from, uint256 amount);
    event ConfigureOraclePrice(uint256 basePrice, uint256 annualizedInterestRate);
    event Initialized(uint64 version);
    event RemoveTokens(address indexed tokenAddress, uint256 amount);
    event RoleAssigned(string indexed role, address indexed address_);
    event RoleRevoked(string indexed role, address indexed address_);
    event SetApprovedSwapper(address indexed approvedSwapper, bool isApproved);
    event SetFeeBounds(
        uint256 minToken0PurchaseFee,
        uint256 maxToken0PurchaseFee,
        uint256 minToken1PurchaseFee,
        uint256 maxToken1PurchaseFee
    );
    event SetOraclePriceBounds(
        uint256 minBasePrice,
        uint256 maxBasePrice,
        uint256 minAnnualizedInterestRate,
        uint256 maxAnnualizedInterestRate
    );
    event SetPaused(bool isPaused);
    event SetTokenPurchaseFees(uint256 token0PurchaseFee, uint256 token1PurchaseFee);
    event SetTokenReceiver(address indexed tokenReceiver);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint256 reserve0, uint256 reserve1);

    function ADMIN_ROLE() external view returns (string memory);
    function AGORA_ACCESS_CONTROL_STORAGE_SLOT() external view returns (bytes32);
    function AGORA_STABLE_SWAP_STORAGE_SLOT() external view returns (bytes32);
    function APPROVED_SWAPPER() external view returns (string memory);
    function FEE_PRECISION() external view returns (uint256);
    function FEE_SETTER_ROLE() external view returns (string memory);
    function PAUSER_ROLE() external view returns (string memory);
    function PRICE_PRECISION() external view returns (uint256);
    function PRICE_SETTER_ROLE() external view returns (string memory);
    function TOKEN_REMOVER_ROLE() external view returns (string memory);
    function WHITELISTER_ROLE() external view returns (string memory);
    function assignRole(string memory _role, address _newAddress, bool _addRole) external;
    function basePrice() external view returns (uint256);
    function calculatePrice(
        uint256 _lastUpdated,
        uint256 _currentTimestamp,
        uint256 _interestRate,
        uint256 _basePrice
    ) external pure returns (uint256 _currentPrice);
    function configureOraclePrice(uint256 _basePrice, uint256 _annualizedInterestRate) external;
    function getAllRoles() external view returns (string[] memory _roles);
    function getAmount0In(
        uint256 _amountOut,
        uint256 _token0OverToken1Price,
        uint256 _token1PurchaseFee
    ) external pure returns (uint256 _amountIn);
    function getAmount0Out(
        uint256 _amountIn,
        uint256 _token0OverToken1Price,
        uint256 _token0PurchaseFee
    ) external pure returns (uint256 _amountOut);
    function getAmount1In(
        uint256 _amountOut,
        uint256 _token0OverToken1Price,
        uint256 _token0PurchaseFee
    ) external pure returns (uint256 _amountIn);
    function getAmount1Out(
        uint256 _amountIn,
        uint256 _token0OverToken1Price,
        uint256 _token1PurchaseFee
    ) external pure returns (uint256 _amountOut);
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
    function getPrice() external view returns (uint256 _currentPrice);
    function getPriceNormalized() external view returns (uint256 _normalizedPrice);
    function getRoleMembers(string memory _role) external view returns (address[] memory _members);
    function hasRole(string memory _role, address _address) external view returns (bool);
    function initialize(InitializeParams memory _params) external;
    function isPaused() external view returns (bool);
    function maxAnnualizedInterestRate() external view returns (uint256);
    function maxBasePrice() external view returns (uint256);
    function maxToken0PurchaseFee() external view returns (uint256);
    function maxToken1PurchaseFee() external view returns (uint256);
    function minAnnualizedInterestRate() external view returns (uint256);
    function minBasePrice() external view returns (uint256);
    function minToken0PurchaseFee() external view returns (uint256);
    function minToken1PurchaseFee() external view returns (uint256);
    function perSecondInterestRate() external view returns (uint256);
    function priceLastUpdated() external view returns (uint256);
    function removeTokens(address _tokenAddress, uint256 _amount) external;
    function requireValidPath(address[] memory _path, address _token0, address _token1) external pure;
    function reserve0() external view returns (uint256);
    function reserve1() external view returns (uint256);
    function setApprovedSwapper(address _approvedSwapper, bool _setApproved) external;
    function setFeeBounds(
        uint256 minToken0PurchaseFee,
        uint256 maxToken0PurchaseFee,
        uint256 minToken1PurchaseFee,
        uint256 maxToken1PurchaseFee
    ) external;
    function setOraclePriceBounds(
        uint256 _minBasePrice,
        uint256 _maxBasePrice,
        uint256 _minAnnualizedInterestRate,
        uint256 _maxAnnualizedInterestRate
    ) external;
    function setPaused(bool _setPaused) external;
    function setTokenPurchaseFees(uint256 _token0PurchaseFee, uint256 _token1PurchaseFee) external;
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
    function token0PurchaseFee() external view returns (uint256);
    function token1() external view returns (address);
    function token1PurchaseFee() external view returns (uint256);
    function tokenReceiverAddress() external view returns (address);
    function version() external pure returns (Version memory _version);
}
