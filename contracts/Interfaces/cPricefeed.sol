pragma solidity >=0.6.0;

interface PriceFeed {
    function getUnderlyingPrice(address cToken) external view returns (uint);
}
