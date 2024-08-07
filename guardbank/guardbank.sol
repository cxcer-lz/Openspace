
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    
    mapping(address => uint256) public deposits;
    mapping(address => address) private _nextDepositors;
    uint256 public listSize;
    address constant GUARD = address(1);
    
    constructor() {
        _nextDepositors[GUARD] = GUARD;
    }
    
    function deposit() public payable {
      require(msg.value > 0, "Deposit amount must be greater than 0");

      address depositor = msg.sender;
      uint256 amount = msg.value;
      //已经存过款，无法再次存款，可以通过调用increaseDeposit增加存款
      require(_nextDepositors[depositor] == address(0),'use increaseDeposit');

      if (_nextDepositors[GUARD] == GUARD) {
          // 第一个用户存款时
          deposits[depositor] = amount;
          _insertDepositor(depositor, GUARD);
      } else {
          // 如果已经有用户存款后
          address current = _nextDepositors[GUARD];
          address prev = GUARD;

          while (current != GUARD && deposits[current] >= amount) {
              prev = current;
              current = _nextDepositors[current];
          }

          require(current != address(0), "Invalid candidateDepositor");

          
          require(_verifyIndex(prev, amount, current));
          deposits[depositor] = amount;
          _insertDepositor(depositor, prev);
      }
    }
    //用户增加存款oldCandidate和newCandidate通过getTopDepositors进行链下计算得到
    function increaseDeposit(address oldCandidate, address newCandidate) public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");

        address depositor = msg.sender;
        uint256 additionalAmount = msg.value;

        uint256 newAmount = deposits[depositor] + additionalAmount;
        updateDeposit(depositor, newAmount, oldCandidate, newCandidate);
    }
    
    function decreaseDeposit(uint256 amount, address oldCandidate, address newCandidate) public {
        //oldCandidate和newCandidate需要通过getTopDepositors进行链下计算得到
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(deposits[msg.sender] >= amount, "Insufficient balance");

        address depositor = msg.sender;
        uint256 remainingBalance = deposits[depositor] - amount;
        deposits[depositor] = remainingBalance;
        payable(depositor).transfer(amount);

        updateDeposit(depositor, remainingBalance, oldCandidate, newCandidate);
    }
    
    function updateDeposit(address depositor, uint256 newAmount, address oldCandidate, address newCandidate) public {
        require(_nextDepositors[depositor] != address(0));
        require(_nextDepositors[oldCandidate] != address(0));
        require(_nextDepositors[newCandidate] != address(0));
        
        if (oldCandidate == newCandidate) {
            require(_isPrevDepositor(depositor, oldCandidate));
            require(_verifyIndex(newCandidate, newAmount, _nextDepositors[depositor]));
            deposits[depositor] = newAmount;
        } else {
            deposits[depositor] = newAmount;
            removeDepositor(depositor, oldCandidate);
            _insertDepositor(depositor, newCandidate);
            
        }
    }
    
    function removeDepositor(address depositor, address candidateDepositor) internal  {
        require(_nextDepositors[depositor] != address(0));
        require(_isPrevDepositor(depositor, candidateDepositor));
        _nextDepositors[candidateDepositor] = _nextDepositors[depositor];
        _nextDepositors[depositor] = address(0);
        listSize--;
    }
    
    function getTopDepositors(uint256 k) public view returns (address[] memory) {
        require(k <= listSize);
        address[] memory topDepositors = new address[](k);
        address current = _nextDepositors[GUARD];
        
        for (uint256 i = 0; i < k; ++i) {
            topDepositors[i] = current;
            current = _nextDepositors[current];
        }
        
        return topDepositors;
    }
    
    function _verifyIndex(address prev, uint256 newValue, address next) internal view returns (bool) {
        return (prev == GUARD || deposits[prev] >= newValue) && (next == GUARD || newValue > deposits[next]);
    }
    
    function _isPrevDepositor(address depositor, address prev) internal view returns (bool) {
        return _nextDepositors[prev] == depositor;
    }
    
    function _insertDepositor(address depositor, address candidateDepositor) private {
        _nextDepositors[depositor] = _nextDepositors[candidateDepositor];
        _nextDepositors[candidateDepositor] = depositor;
        listSize++;
    }
}
