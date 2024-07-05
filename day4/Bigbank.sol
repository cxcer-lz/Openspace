// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import "./bank.sol";

contract BigBank is Bank{
 
    modifier Depositminamount(){
        require(msg.value>0.001 ether,"the doposit amount is little!");
        _;
    } 

    function Deposit()public virtual payable override Depositminamount{
        super.Deposit();
    }

    function transferowner(address newowner)public onlyAdmin{
        require(msg.sender!= address(0),'zero addr!');
        admin= newowner;
    }

}
