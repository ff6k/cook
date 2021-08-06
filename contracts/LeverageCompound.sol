pragma solidity >=0.6.6;
pragma experimental ABIEncoderV2;

import "./DSProxy/DSProxy.sol";
import "./ProxyPermission.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./FlashSwapCompoundHandler.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "hardhat/console.sol";


contract LeveragedBorrowCompound is ProxyPermission {
    using SafeERC20 for IERC20;
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // UniswapV2 factory address
    IUniswapV2Factory constant UniswapV2Factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    function startLeveragedLoan(
      address cCollAddress,
      address cBorrowAddress,
      address srcAddr,
      address destAddr,
      uint srcAmount,
      uint destAmount,
      address payable _FlashSwapCompoundHandler,
      address dsGuardFactoryAddr
    ) public payable {
        address pairAddr;
        // Different transferring mechanism for ETH and ERC20 tokens
        // Transfer user token to proxy
        if (destAddr != ETH_ADDRESS){
          IERC20(destAddr).safeTransferFrom(msg.sender, address(this), destAmount);
        } else {
          require(address(this).balance >= destAmount, "Not enough ETH in account");
        }
        // Give permission to FlashSwapCompoundHandler
        givePermission(_FlashSwapCompoundHandler, dsGuardFactoryAddr);
        bytes memory paramsData = abi.encode(cCollAddress, cBorrowAddress, address(this));
        pairAddr = UniswapV2Factory.getPair(srcAddr, destAddr);
        require(pairAddr != address(0), "Requested token not available");
        // Initiate flash swap
        IUniswapV2Pair(pairAddr).swap(
            srcAmount, destAmount, _FlashSwapCompoundHandler, paramsData);
        removePermission(_FlashSwapCompoundHandler);
    }

    // Unused function
    // function sendDeposit(address payable _compoundReceiver, address _token) internal {
    //     if (_token != ETH_ADDRESS) {
    //         IERC20(_token).transfer(_compoundReceiver, IERC20(_token).balanceOf(address(this)));
    //     }

    //     _compoundReceiver.transfer(address(this).balance);
    // }
}

