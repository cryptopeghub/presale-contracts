//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./utils/ContractGuard.sol";


contract PeghubPresale is ContractGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // governance
    address public operator;
    address public reserveFund;

    IERC20 public peghub;

    IERC20 public bomb;
    IERC20 public btcb;
    // IERC20 public constant peghub = 0x95A6772a2272b9822D4b3DfeEaedF732F1D28DB8;

    // IERC20 public constant bomb = 0x522348779DCb2911539e76A1042aA922F9C47Ee3;
    // IERC20 public constant btcb = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;

    uint256 public startTime;

    uint256 public constant totalTokens = 6000 ether;

    event Purchase(address indexed user, uint256 amount);


    constructor(
        address _peghub,
        address _bomb,
        address _btcb,
        uint256 _startTime)  
    {
        require(block.timestamp < _startTime, "late");
        if (_peghub != address(0)) peghub = IERC20(_peghub);
        if (_bomb != address(0)) bomb = IERC20(_bomb);
        if (_btcb != address(0)) btcb = IERC20(_btcb);
        startTime = _startTime;
        operator = msg.sender;
        reserveFund = msg.sender;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "Presale: caller is not the operator");
        _;
    }

    function availableTokens() public view returns (uint256 _tokens) {
        return IERC20(peghub).balanceOf(address(this));
    }
    
    function soldTokens() public view returns (uint256) {
        return totalTokens.sub(availableTokens());
    }

    function setReserveFund(address _reserveFund) external onlyOperator {
        reserveFund = _reserveFund;
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }


    function buyWithBomb(uint256 _amount) public {
        require(block.timestamp >= startTime, "too early");
        address _sender = msg.sender;

        uint256 _before = bomb.balanceOf(address(this));
        bomb.safeTransferFrom(_sender, address(this), _amount);
        uint256 _after = bomb.balanceOf(address(this));
        _amount = _after - _before;
        bomb.safeTransfer(reserveFund, _amount);

        uint256 peghubToBuy = _amount.mul(110).div(10000);
        uint256 _available = availableTokens();
        require (peghubToBuy <= _available, "not enough tokens");

        safeTokenTransfer(_sender, peghubToBuy);
        emit Purchase(_sender, peghubToBuy);
    }


    function buyWithBtcb(uint256 _amount) public {
        require(block.timestamp >= startTime, "too early");

        address _sender = msg.sender;

        uint256 _before = btcb.balanceOf(address(this));
        btcb.safeTransferFrom(_sender, address(this), _amount);
        uint256 _after = btcb.balanceOf(address(this));
        _amount = _after - _before;
        btcb.safeTransfer(reserveFund, _amount);

        uint256 peghubToBuy = _amount.mul(100);
        uint256 _available = availableTokens();
        require (peghubToBuy <= _available, "not enough tokens");

        safeTokenTransfer(_sender, peghubToBuy);
        emit Purchase(_sender, peghubToBuy);
    }



    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 amount,
        address to
    ) external onlyOperator {
        _token.safeTransfer(to, amount);
    }

    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 _tokenBalance = peghub.balanceOf(address(this));
        if (_tokenBalance > 0) {
            if (_amount > _tokenBalance) {
                peghub.safeTransfer(_to, _tokenBalance);
            } else {
                peghub.safeTransfer(_to, _amount);
            }
        }
    }

}
