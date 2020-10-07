// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.6.0;

import "openzeppelin-solidity/contracts/GSN/Context.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract TokenSwap is Context, Ownable {
    using SafeMath for uint256;

    address public deployer;
    uint256 public swapPeriod;
    uint256 public swapPercentage;
    uint256 public constant PERCENTAGE_DENOMINATOR = 100;

    IERC20 public oldToken;
    IERC20 public newToken;

    struct Swap {
        uint256 totalAmount;
        uint256 withdrawnAmount;
        uint256 initialTime;
        uint256 lastWithdrawTime;
    }

    // mapping (address => uint256) public swappedUsers;
    // mapping(address => Swap[]) public userSwaps;
    mapping(address => bytes32[]) public userSwaps;
    mapping(bytes32 => Swap) public swapsById;

    event TokensSwapped(address indexed user, uint256 indexed amount, bool isInitialSwap);

    constructor (
        address _oldToken,
        address _newToken,
        address _manager,
        uint256 _swapPeriod,
        uint256 _swapPercentage
    ) public {
        require(_oldToken != address(0x0), "TokenSwap: Old token cannot be zero address");
        require(_newToken != address(0x0), "TokenSwap: New token cannot be zero address");
        require(_manager != address(0x0), "TokenSwap: Manager cannot be zero address");
        require(_swapPeriod > 0, "TokenSwap: Swap period cannot be zero");
        oldToken = IERC20(_oldToken);
        newToken = IERC20(_newToken);
        swapPeriod = _swapPeriod;
        swapPercentage = _swapPercentage;
        transferOwnership(_manager);

    }

    function balance() public view returns (uint256) {
        return newToken.balanceOf(address(this));
    }

    function balanceOld() external view returns (uint256) {
        return oldToken.balanceOf(address(this));
    }

    // OWNER FUNCTIONS

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

    // PUBLIC SWAP FUNCTIONS

    function getUserSwaps(address user) public view returns (bytes32[] memory) {
        return userSwaps[user];
    }

    function swapTokens(uint256 amount) public {
        require(
            oldToken.transferFrom(_msgSender(), address(this), amount),
            "TokenSwap: failed to transfer user tokens"
        ); 

        uint256 amountToSend = amount.div(4);

        Swap memory initialSwap = Swap({
             totalAmount: amount,
            withdrawnAmount: amountToSend,
            initialTime: now,
            lastWithdrawTime: 0
        });

        bytes32 swapId = keccak256(abi.encodePacked(msg.sig, _msgSender(), amount, now));

        swapsById[swapId] = initialSwap;
        userSwaps[_msgSender()].push(swapId);

        require(
            newToken.transfer(_msgSender(), amountToSend),
            "TokenSwap: failed to transfer new tokens to user"
        );

        emit TokensSwapped(_msgSender(), amountToSend, true);
    }


    function withdrawRemainingTokens(bytes32 swapId) public {
        Swap storage userSwap = swapsById[swapId];
        // Swap memory userSwap = userSwaps[_msgSender()][swapIndex];

        // uint256 secondsPassed = now - userSwap.initialTime;
        uint256 secondsPassed = userSwap.lastWithdrawTime == 0 ? now .sub(userSwap.initialTime) : now.sub(userSwap.lastWithdrawTime);
        uint256 periodsPassed = secondsPassed.div(swapPeriod);
        periodsPassed = periodsPassed > 3 ? 3 : periodsPassed;

        require (periodsPassed > 0, "TokenSwap: not enough time to withdraw tokens");

        uint256  remainingAmount = userSwap.totalAmount .sub(userSwap.withdrawnAmount);
        uint256 amountToSend = userSwap.totalAmount.mul(periodsPassed).div(4);
        
        if (amountToSend > remainingAmount) {
            amountToSend = remainingAmount;
        }

        userSwap.withdrawnAmount = userSwap.withdrawnAmount.add(amountToSend);
        userSwap.lastWithdrawTime = now;

        require(
            newToken.transfer(_msgSender(), amountToSend),
            "TokenSwap: failed to transfer new tokens to user"
        );

        emit TokensSwapped(_msgSender(), amountToSend, false);
    }
}
