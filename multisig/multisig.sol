
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {
    //所有owner的成员
    address[] public owners;
    //要求确认的次数
    uint public numConfirmationsRequired;
    struct Transaction {
        address to;
        uint value;
        bool executed;
        address[] confirmedBy;
    }

    Transaction[] public transactions;

    event Deposit(address indexed sender, uint value);
    event SubmitTransaction(address indexed owner, uint indexed txIndex, address indexed to, uint value);
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Not an owner");
        _;
    }
    //提案是否存在
    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "Transaction does not exist");
        _;
    }
    //提案是否被执行
    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "Transaction already executed");
        _;
    }
    //提案是否被确认
    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed(_txIndex, msg.sender), "Transaction already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
        require(_owners.length > 0, "Owners required");
        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length, "Invalid number of confirmations");
        owners = _owners;
        numConfirmationsRequired = _numConfirmationsRequired;
    }
    //向多签地址存入eth
    function deposit() public payable {
        emit Deposit(msg.sender, msg.value);
    }
    //检测是否是owner
    function isOwner(address _owner) public view returns (bool) {
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == _owner) {
                return true;
            }
        }
        return false;
    }
    //只有owner可以发起提案
    function proposeTx(address _to, uint _value) public onlyOwner {
        address[] memory emptyAddressArray;
        transactions.push(Transaction({
            to: _to,
            value: _value,
            executed: false,
            confirmedBy: emptyAddressArray
        }));
        emit SubmitTransaction(msg.sender, transactions.length - 1, _to, _value);
    }
    //对提案进行确认
    function confirm(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        transactions[_txIndex].confirmedBy.push(msg.sender);
        emit ConfirmTransaction(msg.sender, _txIndex);
    }
    //执行提案，检测是否存在提案，该提案是否被执行过
    function executeTx(uint _txIndex) public txExists(_txIndex) notExecuted(_txIndex) {
        require(transactions[_txIndex].confirmedBy.length >= numConfirmationsRequired, "Not enough confirmations");
        Transaction storage transaction = transactions[_txIndex];
        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}("");
        require(success, "Execution failed");
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    receive() external payable {
        deposit();
    }
    //检测该地址是否确认过某个提案
    function isConfirmed(uint _txIndex, address _owner) public view returns (bool) {
        Transaction storage transaction = transactions[_txIndex];
        for (uint i = 0; i < transaction.confirmedBy.length; i++) {
            if (transaction.confirmedBy[i] == _owner) {
                return true;
            }
        }
        return false;
    }
}
