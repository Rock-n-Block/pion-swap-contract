// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.6.0;

import "./openzeppelin-solidity/contracts/access/Ownable.sol";
import "./openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./TokenVault.sol";

contract PionSwap is Ownable {
    IERC20 public oldToken;
    IERC20 public newToken;
    TokenVault public newTokenVault;

    mapping (address => uint256) public swappedUsers;

    event Swap(address indexed user, uint256 indexed amount);

    constructor (
        address _oldToken,
        address _newToken
    ) public {
        oldToken = IERC20(_oldToken);
        newToken = IERC20(_newToken);
        newTokenVault = new TokenVault(newToken);

    }

    function setOldToken(address _oldToken) external onlyOwner {
        require(
            _oldToken != address(0x0),
            "TokenSwap: address cannot be zero"
        );
        oldToken = IERC20(_oldToken);
    }

    function setNewToken(address _newToken) external onlyOwner {
        require(
            _newToken != address(0x0),
            "TokenSwap: address cannot be zero"
        );
        newToken = IERC20(_newToken);
    }

    function getSwappedAmount(address user) external  view returns (uint256 swapAmount) {
        return swappedUsers[user];
    }

    function swapTokens(uint256 amount) external  {
        require(
            oldToken.transferFrom(msg.sender, address(this), amount),
            "TokenSwap: failed to transfer tokens"
        );

        swappedUsers[msg.sender] = amount;

        newToken.transfer(msg.sender, amount);

        emit Swap(msg.sender, amount);
    }
}
