pragma solidity >=0.6.6;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import './libraries/UniswapV2Library.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import "./Interfaces/DSProxyInterface.sol";
import "./Interfaces/CTokenInterface.sol";
import "./Interfaces/CEtherInterface.sol";
import "./Interfaces/ComptrollerInterface.sol";
import "./CompoundBorrowRepay.sol";
import "./ProxyRegistry.sol";
import "hardhat/console.sol";

contract FlashSwapCompoundHandler is IUniswapV2Callee {
    using SafeERC20 for IERC20;

    address public constant COMPTROLLER_ADDR = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    address public constant UNISWAP_V2_FACTORY_ADDR = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant CETH_ADDRESS = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    ProxyRegistry public constant proxyRegistry = ProxyRegistry(0x2E82103bD91053C781aaF39da17aE58ceE39d0ab);

    event Logger(string, uint);

    constructor() public {}

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        address token0 = IUniswapV2Pair(msg.sender).token0(); // fetch the address of token0
        address token1 = IUniswapV2Pair(msg.sender).token1(); // fetch the address of token1
        assert(msg.sender == IUniswapV2Factory(UNISWAP_V2_FACTORY_ADDR).getPair(token0, token1)); // ensure that msg.sender is a V2 pair
        assert(amount0 == 0 || amount1 == 0); // this strategy is unidirectional
        address uniswapBorrowToken = amount0 == 0 ? token1 : token0;
        address uniswapRepayToken = amount0 == 0 ? token0 : token1;
        uint uniswapBorrowTokenAmount = amount0 == 0 ? amount1 : amount0;
        uint repaySingleTokenAmount;
        (
            address cCollateralToken,
            address cBorrowToken,
            address dsProxy
        ) = abi.decode(data, (address,address,address));
        // Send loaned asset to DsProxy
        IERC20(uniswapBorrowToken).safeTransfer(dsProxy, IERC20(uniswapBorrowToken).balanceOf(address(this)));
        // get Compound proxy address
        // address compoundProxyAddress = proxyRegistry.getAddr("COMP_PROXY");
        // Execute the DsProxy call to open loan on Compound
        bytes memory openLoanLogicData = abi.encodeWithSignature(
            "openLoan(address,address,uint256)",
            // compoundProxyAddress,
            cCollateralToken,
            cBorrowToken,
            uniswapBorrowTokenAmount);
        // bytes memory openLoanLogicData = abi.encodeWithSignature(
        //     "borrowEth(uint,address,address,uint256)",
        //     uniswapBorrowTokenAmount,
        //     cCollateralToken,
        //     cBorrowToken,
        //         );
        // console.log("FlashSwapCompoundHandler: FlashSwapCompoundHandler address %s", address(this));
        // console.log("FlashSwapCompoundHandler: openLoanLogicData %s, %s, %s", cCollateralToken, cBorrowToken, uniswapBorrowTokenAmount);
        DSProxyInterface(dsProxy).execute(address(this), openLoanLogicData);
        // DSProxyInterface(dsProxy).execute(compoundProxyAddress, openLoanLogicData);
        // console.log("FlashSwapCompoundHandler: dsProxy %s", dsProxy);
        // Repay the loan with the money DSProxy sent back. msg.sender here is uniswap pair.
        address[] memory path = new address[](2);
        path[0] = uniswapRepayToken;
        path[1] = uniswapBorrowToken;
        console.log(uniswapRepayToken);
        uint repayAmount = UniswapV2Library.getAmountsIn(UNISWAP_V2_FACTORY_ADDR, uniswapBorrowTokenAmount, path)[0];
        console.log(repayAmount);
        console.log(IERC20(uniswapRepayToken).balanceOf(address(this)));
        console.log(IERC20(uniswapBorrowToken).balanceOf(address(this)));
        IERC20(uniswapRepayToken).safeTransfer(msg.sender, UniswapV2Library.getAmountsIn(UNISWAP_V2_FACTORY_ADDR, uniswapBorrowTokenAmount, path)[0]);
    }

    // Context: DSProxy
    function openLoan(// address compoundProxy,
                      address cCollateralToken, address cBorrowToken, uint uniswapBorrowTokenAmount) public {
        console.log(address(this));
        // address compoundborrowrepay = CompoundBorrowRepay(compoundProxy);
        address collateralToken = getUnderlyingAddr(cCollateralToken);
        address borrowToken = getUnderlyingAddr(cBorrowToken);
        // address collateralToken = CTokenInterface(cCollateralToken).underlying();
        // address borrowToken = CTokenInterface(cBorrowToken).underlying();
        // uint collateralTokenAmount = IERC20(collateralToken).balanceOf(address(this));
        uint collateralTokenAmount = getProxyBalance(address(this), collateralToken);
        uint underlyingDecimal = 6;
        depositCompound(collateralToken, cCollateralToken, collateralTokenAmount);
        // draw debt
        borrowCompound(cBorrowToken, uniswapBorrowTokenAmount);
        // compoundborrowrepay.borrowErc20(
        //     cCollateralToken,
        //     underlyingDecimal,
        //     uniswapBorrowTokenAmount
        // );
        // Send back to repay uniswap flash swap. msg.sender here is FlashSwapCompoundHandler.
        IERC20(borrowToken).safeTransfer(msg.sender, IERC20(borrowToken).balanceOf(address(this)));
    }

    function getProxyBalance(address _account, address _token) internal returns (uint) {
        if (_token == ETH_ADDRESS) {
            return _account.balance;
        } else {
            return IERC20(_token).balanceOf(_account);
        }
    }


    function getUnderlyingAddr(address _cTokenAddress) internal returns (address) {
        if (_cTokenAddress == CETH_ADDRESS) {
            return ETH_ADDRESS;
        } else {
            return CTokenInterface(_cTokenAddress).underlying();
        }
    }

    // Context: DSProxy
    function depositCompound(address token, address cToken, uint amount) internal {
        if (token != ETH_ADDRESS) {
            IERC20(token).safeApprove(cToken, uint(-1));
        }
        enterMarket(cToken);
        if (token != ETH_ADDRESS) {
            require(CTokenInterface(cToken).mint(amount) == 0, "mint error");
        } else {
            CEtherInterface(cToken).mint{value:amount}();
        }
    }

    // Context: DSProxy
    function borrowCompound(address cToken, uint amount) internal {
        enterMarket(cToken);
        require(CTokenInterface(cToken).borrow(amount) == 0);
    }

    // Context: DSProxy
    function enterMarket(address cToken) public {
        address[] memory markets = new address[](1);
        markets[0] = cToken;
        ComptrollerInterface(COMPTROLLER_ADDR).enterMarkets(markets);
    }
}
