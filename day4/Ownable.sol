// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import "./Bigbank.sol";

interface IBank {
    function Deposit()external payable;
    function withdraw(uint)external; 
}

contract Ownable{
    address public owner;
    constructor() {
        owner=msg.sender;
    }

    receive() external payable {
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function withdraw(address bigbank_address,uint amount)public onlyOwner {
        IBank(bigbank_address).withdraw(amount);
    }

    function transferadmin(address newadmin)public onlyOwner{
        require(msg.sender!= address(0),'zero addr!');
        owner=newadmin;
    }

}
