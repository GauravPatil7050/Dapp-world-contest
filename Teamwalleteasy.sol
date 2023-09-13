// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TeamWallet {
    address public deployer;  
    address[] public members;
    uint public totalCredits;      
    
    struct Transaction {
        uint amount;
        
        uint executed; 
        uint approvals;
        uint rejections;
    }
    
    Transaction[] public transactions;
    
    mapping(address => mapping(uint => bool)) public hasApproved;
    mapping(address => mapping(uint => bool)) public hasRejected;

    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only the deployer can call this function");
        _;
    }

    modifier onlyTeamMember() {
        require(isTeamMember(msg.sender), "Only team members can call this function");
        _;
    }

    constructor() {
        deployer = msg.sender;
        
        transactions.push(Transaction(0,0,0,0));
    }

    function isTeamMember(address _address) internal view returns (bool) {
        for (uint i = 0; i < members.length; i++) {
            if (members[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function setWallet(address[] memory _members, uint _totalCredits) public onlyDeployer {
        require(members.length == 0, "Wallet has already been initialized"); 
        require(_members.length > 0, "There must be at least one team member");
        require(_totalCredits > 0, "Credits must be greater than 0");
        require(deployer != _members[0], "The deployer cannot be a team member"); 

        for (uint i = 0; i < _members.length; i++) {
            
            members.push(_members[i]);
        }
        totalCredits = _totalCredits;
    }

    function spend(uint _amount) public onlyTeamMember {
        require(_amount > 0, "Amount must be greater than 0");
        
        
        
        if (_amount > credits()) {
            transactions.push(Transaction(_amount, 2, 1, 0)); 
        } else {
            transactions.push(Transaction(_amount, 0, 1, 0)); 
        }
        hasApproved[msg.sender][transactions.length - 1] = true;

        
        if (members.length == 1) {
            if (transactions[transactions.length - 1].executed == 0) {
                totalCredits -= _amount;
                transactions[transactions.length - 1].executed = 1;
            }
        }
        
    }

    function approve(uint _n) public onlyTeamMember {
        require(_n < transactions.length && _n != 0, "Invalid transaction index"); 
        require(transactions[_n].executed == 0, "Executed"); 
        require(!hasApproved[msg.sender][_n], "Approval already recorded");
        require(!hasRejected[msg.sender][_n], "Transaction already rejected");
        
        transactions[_n].approvals++;
        hasApproved[msg.sender][_n] = true;

        
        execTx(_n);
    }

    function reject(uint _n) public onlyTeamMember {
        require(_n < transactions.length && _n != 0, "Invalid transaction index"); 
        require(transactions[_n].executed == 0, "Executed"); 
        require(!hasApproved[msg.sender][_n], "Transaction already approved");
        require(!hasRejected[msg.sender][_n], "Rejection already recorded");
        
        
        transactions[_n].rejections++;
        hasRejected[msg.sender][_n] = true;
        
        execTx(_n);
    }

    
    function execTx(uint _n) internal {
        
        uint _approvals = transactions[_n].approvals;
        uint _rejections = transactions[_n].rejections;

        
        if ((_approvals * 100) / members.length >= 70) {
    
            require(transactions[_n].executed == 0, "Executed");
            totalCredits -= transactions[_n].amount;
            transactions[_n].executed = 1;
        }

        
        if ((_rejections * 100) / members.length > 30) {
            transactions[_n].executed = 2;
        }
    }

    function credits() public view onlyTeamMember returns (uint) {
        return totalCredits;
    }

    function viewTransaction(uint _n) public view onlyTeamMember returns (uint amount, string memory status) {
        require(_n < transactions.length, "Invalid transaction index");
        amount = transactions[_n].amount;

        if (transactions[_n].executed == 1) {
            status = "debited";
        } else if (transactions[_n].executed == 0) {
            status = "pending";
        } else {
            status = "failed";
        }

   
    }
}