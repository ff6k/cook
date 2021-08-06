pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interfaces/CEth.sol";
import "./Interfaces/CErc20.sol";
import "./Interfaces/cPricefeed.sol";
import "./Interfaces/ComptrollerInterface.sol";


contract CompoundBorrowRepay {
    address public constant COMPTROLLER_ADDR = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant CETH_ADDRESS = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    // Price feed from UniswapAnchoredView
    // address public constant PRICEFEED_ADDRESS = 0x922018674c12a7f0d394ebeef9b58f186cde13c1;

    struct AccountInfo {
        uint liquidity;
        uint shortfall;
    }

    struct MarketInfo {
        bool isListed;
        uint collateralFactorMantissa;
        uint borrowRateMantissa;
    }

    event Logger(string, uint256);

    function borrowErc20(
        // address payable _cEtherAddress,
        // address _comptrollerAddress,
        // address _priceFeedAddress,
        address _cTokenAddress,
        uint _underlyingDecimals,
        uint _borrowAmount
    ) public payable returns (uint256) {
        CEth cEth = CEth(CETH_ADDRESS);
        Comptroller comptroller = Comptroller(COMPTROLLER_ADDR);
        // PriceFeed priceFeed = PriceFeed(PRICEFEED_ADDRESS);
        CErc20 cToken = CErc20(_cTokenAddress);

        // Supply ETH as collateral, get cETH in return
        cEth.mint.value(msg.value)();

        // Enter the ETH market so you can borrow another type of asset
        address[] memory cTokens = new address[](1);
        cTokens[0] = CETH_ADDRESS;
        uint256[] memory errors = comptroller.enterMarkets(cTokens);
        if (errors[0] != 0) {
            revert("Comptroller.enterMarkets failed.");
        }

        // Get my account's total liquidity value in Compound
        (uint256 error, uint256 liquidity, uint256 shortfall) = comptroller
            .getAccountLiquidity(address(this));
        if (error != 0) {
            revert("Comptroller.getAccountLiquidity failed.");
        }
        require(shortfall == 0, "account underwater");
        require(liquidity > 0, "account has excess collateral");

        // Get the collateral factor for our collateral
        (
          bool isListed,
          uint collateralFactorMantissa
        ) = comptroller.markets(CETH_ADDRESS);
        emit Logger('ETH Collateral Factor', collateralFactorMantissa);

        // Get the amount of underlying added to your borrow each block
        uint borrowRateMantissa = cToken.borrowRatePerBlock();
        emit Logger('Current Borrow Rate', borrowRateMantissa);

        // Get the underlying price in USD from the Price Feed,
        // so we can find out the maximum amount of underlying we can borrow.
        // uint256 underlyingPrice = priceFeed.getUnderlyingPrice(_cTokenAddress);
        // uint256 maxBorrowUnderlying = liquidity / underlyingPrice;

        // Borrowing near the max amount will result
        // in your account being liquidated instantly
        // emit Logger("Maximum underlying Borrow (borrow far less!)", maxBorrowUnderlying);

        // Borrow underlying
        // uint256 numUnderlyingToBorrow = 10;

        // Borrow, check the underlying balance for this contract's address
        cToken.borrow(_borrowAmount * 10**_underlyingDecimals);

        // Get the borrow balance
        uint256 borrows = cToken.borrowBalanceCurrent(address(this));
        emit Logger("Current underlying borrow amount", borrows);

        return borrows;
    }

    function repayErc20(
        address _erc20Address,
        address _cErc20Address,
        uint256 amount
    ) public returns (bool) {
        IERC20 underlying = IERC20(_erc20Address);
        CErc20 cToken = CErc20(_cErc20Address);

        underlying.approve(_cErc20Address, amount);
        uint256 error = cToken.repayBorrow(amount);

        require(error == 0, "CErc20.repayBorrow Error");
        return true;
    }

    function borrowEth(
        // address payable _cEtherAddress,
        // address _comptrollerAddress,
        uint numWeiToBorrow,
        address _cTokenAddress,
        address _underlyingAddress,
        uint256 _underlyingToSupplyAsCollateral
    ) public returns (uint) {
        // AccountInfo memory accountInfo;
        // MarketInfo memory marketInfo;
        CEth cEth = CEth(CETH_ADDRESS);
        Comptroller comptroller = Comptroller(COMPTROLLER_ADDR);
        CErc20 cToken = CErc20(_cTokenAddress);
        IERC20 underlying = IERC20(_underlyingAddress);
        uint error;

        // Approve transfer of underlying
        underlying.approve(_cTokenAddress, _underlyingToSupplyAsCollateral);

        // Supply underlying as collateral, get cToken in return
        error = cToken.mint(_underlyingToSupplyAsCollateral);
        require(error == 0, "CErc20.mint Error");

        // Enter the market so you can borrow another type of asset
        address[] memory cTokens = new address[](1);
        cTokens[0] = _cTokenAddress;
        uint256[] memory errors = comptroller.enterMarkets(cTokens);
        if (errors[0] != 0) {
            revert("Comptroller.enterMarkets failed.");
        }

        // Get my account's total liquidity value in Compound

        // (error, accountInfo.liquidity, accountInfo.shortfall) = comptroller
        //     .getAccountLiquidity(address(this));
        // if (error != 0) {
        //     revert("Comptroller.getAccountLiquidity failed.");
        // }
        // require(accountInfo.shortfall == 0, "account underwater");
        // require(accountInfo.liquidity > 0, "account has excess collateral");

        // Borrowing near the max amount will result
        // in your account being liquidated instantly
        // emit Logger("Maximum ETH Borrow (borrow far less!)", accountInfo.liquidity);

        // // Get the collateral factor for our collateral
        // (
        //   marketInfo.isListed,
        //   marketInfo.collateralFactorMantissa
        // ) = comptroller.markets(_cTokenAddress);
        // emit Logger('Collateral Factor', marketInfo.collateralFactorMantissa);

        // // Get the amount of ETH added to your borrow each block
        uint borrowRateMantissa = cEth.borrowRatePerBlock();
        emit Logger('Current ETH Borrow Rate', borrowRateMantissa);

        // Borrow a fixed amount of ETH below our maximum borrow amount
        // uint256 numWeiToBorrow = 20000000000000000; // 0.02 ETH

        // Borrow, then check the underlying balance for this contract's address
        cEth.borrow(numWeiToBorrow);

        uint256 borrows = cEth.borrowBalanceCurrent(address(this));
        emit Logger("Current ETH borrow amount", borrows);

        return borrows;
    }

    function repayEth(
        // address _cEtherAddress,
        uint256 amount)
        public
        returns (bool)
    {
        CEth cEth = CEth(CETH_ADDRESS);
        cEth.repayBorrow.value(amount)();
        return true;
    }

    // Need this to receive ETH when `borrowEthExample` executes
    receive() external payable {}
}
