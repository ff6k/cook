pragma solidity >=0.6.0;

import "./DSProxy/DSGuard.sol";
import "./DSProxy/DSAuth.sol";
import "hardhat/console.sol";

contract ProxyPermission {
    // Cook protocol factory address
    address public constant FACTORY_ADDRESS = 0x5a15566417e6C1c9546523066500bDDBc53F88C7;

    /// @notice Called in the context of DSProxy to authorize an address
    /// @param _contractAddr Address which will be authorized
    function givePermission(address _contractAddr, address _guardFactory) public {
        // console.log("address(this) in ProxyPermission: %s", address(this));
        address currAuthority = address(DSAuth(address(this)).authority());
        // console.log("currAuthority of Proxy: %s", currAuthority);
        DSGuard guard = DSGuard(currAuthority);

        if (currAuthority == address(0)) {
            guard = DSGuardFactory(_guardFactory).newGuard();
            DSAuth(address(this)).setAuthority(DSAuthority(address(guard)));
            // console.log("create new guard for Proxy: %s", address(guard));
        }
        // console.log("FlashSwapCompoundHandler address: %s", _contractAddr);
        // console.log("new guard owner: %s", guard.owner());
        guard.permit(_contractAddr, address(this), bytes4(keccak256("execute(address,bytes)")));
        // console.log("Guard give FlashSwapCompoundHandler permit to DSProxy.execute(address, bytes)");
    }

    /// @notice Called in the context of DSProxy to remove authority of an address
    /// @param _contractAddr Auth address which will be removed from authority list
    function removePermission(address _contractAddr) public {
        address currAuthority = address(DSAuth(address(this)).authority());

        // if there is no authority, that means that contract doesn't have permission
        if (currAuthority == address(0)) {
            return;
        }

        DSGuard guard = DSGuard(currAuthority);
        guard.forbid(_contractAddr, address(this), bytes4(keccak256("execute(address,bytes)")));
    }

    function proxyOwner() internal returns(address) {
        return DSAuth(address(this)).owner();
    }
}
