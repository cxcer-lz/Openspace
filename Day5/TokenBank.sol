// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
   
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


contract TokenBank{
    address admin;
    uint MAX_UINT=2**256 - 1;
    IERC20 public token;
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed owner, uint256 amount);

    constructor(address tokenAddress){
        admin=msg.sender;
        token=IERC20(tokenAddress);

    }

    modifier onlyowner(){
        require(msg.sender==admin,"Only owner can call this function");
        _;
    }

    receive() external payable {
    }

    function deposit(uint256 amount) public {
        require(amount>0,"amount exceeds balance!");
        token.transfer(address(this), amount);
    }



    function withdraw(uint256 amount) public onlyowner{
        require(amount > 0, "Amount must be greater than zero");
        token.approve(address(this),amount);
        token.transferFrom(address(this), admin, amount);
    }
    
}
