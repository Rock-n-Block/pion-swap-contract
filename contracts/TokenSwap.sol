// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.6.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract TokenSwap is Ownable {
    address public deployer;

    IERC20 public oldToken;
    IERC20 public newToken;

    struct Swap {
        uint256 tokenAmount;
        uint256 initialTime;
        bool[3] remainderClaimed;
    }

    // mapping (address => uint256) public swappedUsers;
    mapping(address => Swap[]) public userSwaps;

    event TokensSwapped(address indexed user, uint256 indexed amount);

    constructor (
        address _oldToken,
        address _newToken,
        address _manager
    ) public {
        require(_oldToken != address(0x0), "TokenSwap: Old token cannot be zero address");
        require(_newToken != address(0x0), "TokenSwap: New token cannot be zero address");
        require(_manager != address(0x0), "TokenSwap: Manager cannot be zero address");
        oldToken = IERC20(_oldToken);
        newToken = IERC20(_newToken);
        transferOwnership(_manager);

    }

    function balance() public view returns (uint256) {
        return newToken.balanceOf(address(this));
    }

    function balanceOld() external view returns (uint256) {
        return oldToken.balanceOf(address(this));
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

    function withdrawNewToken(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0x0), "TokenSwap: withdraw address cannot be zero");
        require(_to != address(this), "TokenSwap: withdraw address cannot this contract");
        require(_amount >= balance(), "TokenSwap: transfer amount exceeds balance");
        require(
            newToken.transfer(_to, _amount),
            "TokenSwap: failed to withdraw tokens"
        );
    }

    function withdrawCustomToken(IERC20 _token, address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0x0), "TokenSwap: withdraw address cannot be zero");
        require(_to != address(this), "TokenSwap: withdraw address cannot this contract");
        require(address(_token) != address(oldToken), "TokenSwap: cannot withdraw old token");
        require(
            _token.transfer(_to, _amount),
            "TokenSwap: failed to withdraw tokens"
        );
    }

    function getSwappedAmount(address user) external  view returns (uint256 swapAmount) {
        return swappedUsers[user];
    }

    function swapTokens(uint256 amount) external  {
        require(
            oldToken.transferFrom(msg.sender, address(this), amount),
            "TokenSwap: failed to transfer user tokens"
        );

        swappedUsers[msg.sender] = amount;

        require(
            newToken.transfer(msg.sender, amount),
            "TokenSwap: failed to transfer new tokens to user"
        );

        emit Swap(msg.sender, amount);
    }
}
