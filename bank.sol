pragma solidity ^0.8.24;

contract Bank{
    receive() external payable { 
    }
    mapping (address=>uint256) public balances;
    address admin;
    address[3] public topdespoit;
    constructor(){
       admin=msg.sender; 
       balances[0x0000000000000000000000000000000000000000]=0;
    }

    function Deposit()public payable{
        balances[msg.sender]+=msg.value;
        if ((msg.value>balances[topdespoit[0]]) && !doublecheck(msg.sender)){
            topdespoit[2]=topdespoit[1];
            balances[topdespoit[2]]=balances[topdespoit[1]];
            topdespoit[1]=topdespoit[0];
            balances[topdespoit[1]]=balances[topdespoit[0]];
            topdespoit[0]=msg.sender;
            balances[topdespoit[0]]=msg.value;
        }else if((msg.value>balances[topdespoit[1]]) && !doublecheck(msg.sender)){
            topdespoit[2]=topdespoit[1];
            balances[topdespoit[2]]=balances[topdespoit[1]];
            topdespoit[1]=msg.sender;
            balances[topdespoit[1]]=msg.value;
        }else if((msg.value>balances[topdespoit[2]]) && !doublecheck(msg.sender)){
            topdespoit[2]=msg.sender;
            balances[topdespoit[2]]=msg.value;
        }
        
    }

    function doublecheck(address addr)internal view returns(bool){
        for (uint256 i = 0; i < topdespoit.length; i++) {
            if (topdespoit[i] == addr) {
                return true;
            } 
        }
        return false;

    
    }

    function withdraw()public {
        require(msg.sender==admin,'not admin!');
        address sender_address=address(this);
        uint value = sender_address.balance;
        address receive_address=msg.sender;
        payable(receive_address).transfer(value);

    }

}
