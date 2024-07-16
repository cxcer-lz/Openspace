// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
   
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function permit(address holder, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    
}

contract TokenBank {
    using SafeMath for uint256;

    IERC20 public token;
    mapping(address => uint256) public deposits;


    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address _token) {
        token =IERC20(_token);
    }

    function deposit(uint256 _amount) public {
        require(_amount > 0, "Deposit amount must be greater than 0");
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        deposits[msg.sender] = deposits[msg.sender].add(_amount);
        emit Deposit(msg.sender, _amount);
    }

    function tokensReceived(address sender,uint amount)external returns(bool) {
        deposits[sender] = deposits[sender].add(amount);
        return true;
    }

    function withdraw(uint256 _amount) public {
        require(_amount <= deposits[msg.sender], "Insufficient deposit");
        deposits[msg.sender] = deposits[msg.sender].sub(_amount);
        require(token.transfer(msg.sender, _amount), "Transfer failed");
        emit Withdraw(msg.sender, _amount);
    }

    function permitDeposit(address owner,address spender, uint256 value,uint256 deadline,uint8 v, bytes32 r, bytes32 s)public {
        token.permit(owner,spender,value,deadline,v,r,s);
        require(token.transferFrom(owner, spender, value), "Transfer failed");
        deposits[spender] = deposits[spender].add(value);
    }

    function getBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

}