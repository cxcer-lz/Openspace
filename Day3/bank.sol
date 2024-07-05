// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

contract Bank{
    mapping (address=>uint256) public balances;
    address admin;
    address[3] public topdespoit;
    constructor(){
       admin=msg.sender; 
    }

    function Deposit()public payable{
        require(msg.value>0,"the min deposit must be greate than 0");
        balances[msg.sender]+=msg.value;
        if ((msg.value>balances[topdespoit[0]]) && !Check(msg.sender)){
            topdespoit[2]=topdespoit[1];
            balances[topdespoit[2]]=balances[topdespoit[1]];
            topdespoit[1]=topdespoit[0];
            balances[topdespoit[1]]=balances[topdespoit[0]];
            topdespoit[0]=msg.sender;
            balances[topdespoit[0]]=msg.value;
        }else if((msg.value>balances[topdespoit[1]]) && !Check(msg.sender)){
            topdespoit[2]=topdespoit[1];
            balances[topdespoit[2]]=balances[topdespoit[1]];
            topdespoit[1]=msg.sender;
            balances[topdespoit[1]]=msg.value;
        }else if((msg.value>balances[topdespoit[2]]) && !Check(msg.sender)){
            topdespoit[2]=msg.sender;
            balances[topdespoit[2]]=msg.value;
        }
        
    }

    //check the sender if in topdespoit 
    function Check(address addr)internal view returns(bool){
        for (uint256 i = 0; i < topdespoit.length; i++) {
            if (topdespoit[i] == addr) {
                return true;
            } 
        }
        return false;
    }

    function withdraw(uint amount)public {
        require(msg.sender==admin,'must be admin!');
        address receive_address=msg.sender;
        payable(receive_address).transfer(amount);

    }

}

