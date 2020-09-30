// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.6.0;

import "./openzeppelin-solidity/contracts/access/Ownable.sol";
import "./openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";


contract TokenVault is Ownable {
    IERC20 public token;

    constructor(IERC20 _token) public {
        token = _token;
    }

    function balance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function transfer(address to, uint256 value) external onlyOwner returns (bool) {
        return token.transfer(to, value);
    }

    function transferCustom(address customToken, address to, uint256 amount) external onlyOwner returns (bool) {
        require(address(token) != customToken, 'TokenPool: Cannot claim token held by the contract');

        return IERC20(customToken).transfer(to, amount);
    }
}
