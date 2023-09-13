// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TeamWallet {
    uint256 transactionId = 1;
    error TransactionFailed();
    enum TransactionStatus {
        pending,
        debited,
        failed
    }

    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier OnlyDeployer() {
        require(
            msg.sender == owner,
            "Transaction Failed: Only the deployer can call this function"
        );
        _;
    }

    struct TransactionRecord {
        uint256 requestId;
        address requestedAddress;
        uint256 requestedAmount;
        uint256 approved;
        uint256 rejected;
        TransactionStatus status;
    }

    TransactionRecord[] private transactionRecord;
    mapping(uint256 => TransactionRecord) private mapToTransaction;
    mapping(uint256 => bool) private IdExist;

    mapping(address => bool) private isMember;
    address[] private memberArray;
    uint256 public credit;
    uint256 private approvedPercentage;
    uint256 private rejectPercentage;
    bool private isExecuted = false;
    mapping(address => mapping(uint256 => bool)) private didIApproved;
    mapping(address => mapping(uint256 => bool)) private didIRejected;
    uint256 public pending = 0;
    uint256 public debitedCount2 = 0;
    uint256 public failed = 0;

    function setWallet(address[] memory members, uint256 _credits) public OnlyDeployer {
        require(
            members.length >= 1,
            "Transaction Failed: At least one member required"
        );
        require(
            _credits > 0,
            "Transaction Failed: Credits must be greater than zero"
        );
        require(
            !isExecuted,
            "Transaction Failed: Wallet setup already executed"
        );

        for (uint256 i = 0; i < members.length; i++) {
            require(
                members[i] != owner,
                "Transaction Failed: Deployer cannot be a team member."
            );
            isMember[members[i]] = true;
            memberArray.push(members[i]);
        }

        isExecuted = true;
        credit = _credits;
        approvedPercentage = (members.length * 1000000 * 70) / 100;
        approvedPercentage = approvedPercentage / 1000000;
        rejectPercentage = (members.length * 1000000 * 31) / 100;
        rejectPercentage = rejectPercentage / 1000000;
    }

    function spend(uint256 amount) public {
        require(
            isMember[msg.sender],
            "Transaction Failed: Only team members can spend"
        );
        require(
            amount > 0,
            "Transaction Failed: Amount must be greater than zero"
        );

        uint Id = transactionId;
        mapToTransaction[Id] = TransactionRecord(
            Id,
            msg.sender,
            amount,
            0,
            0,
            TransactionStatus.pending
        );
        didIApproved[msg.sender][Id] = true;
        mapToTransaction[Id].approved += 1;
        pending += 1;
        IdExist[Id] = true;

        if (
            memberArray.length < 2 &&
            mapToTransaction[Id].requestedAmount <= credit
        ) {
            mapToTransaction[Id].status = TransactionStatus.debited;
            credit -= mapToTransaction[Id].requestedAmount;
            pending -= 1;
            debitedCount2 += 1;
        } else if (mapToTransaction[Id].requestedAmount > credit) {
            mapToTransaction[Id].status = TransactionStatus.failed;
            failed += 1;
            pending -= 1;
        }

        transactionId++;
    }

    function approve(uint256 n) public {
        require(
            isMember[msg.sender],
            "Transaction Failed: Only team members can approve"
        );
        require(
            IdExist[n],
            "Transaction Failed: Transaction ID does not exist"
        );
        require(
            !didIApproved[msg.sender][n],
            "Transaction Failed: Already approved"
        );
        require(
            mapToTransaction[n].requestedAmount <= credit,
            "Transaction Failed: Insufficient credit"
        );
        require(
            mapToTransaction[n].status == TransactionStatus.pending,
            "Transaction Failed: Transaction is not pending"
        );

        didIApproved[msg.sender][n] = true;
        mapToTransaction[n].approved += 1;

        if (mapToTransaction[n].approved > approvedPercentage) {
            mapToTransaction[n].status = TransactionStatus.debited;
            credit -= mapToTransaction[n].requestedAmount;
            pending -= 1;
            debitedCount2 += 1;
        }
    }

    function reject(uint256 n) public {
        require(
            isMember[msg.sender],
            "Transaction Failed: Only team members can reject"
        );
        require(
            IdExist[n],
            "Transaction Failed: Transaction ID does not exist"
        );
        require(
            !didIApproved[msg.sender][n],
            "Transaction Failed: Already approved"
        );
        require(
            mapToTransaction[n].requestedAmount <= credit,
            "Transaction Failed: Insufficient credit"
        );
        require(
            mapToTransaction[n].status == TransactionStatus.pending,
            "Transaction Failed: Transaction is not pending"
        );

        didIApproved[msg.sender][n] = true;

        mapToTransaction[n].rejected += 1;
        failed += 1;
        pending -= 1;
        if (mapToTransaction[n].rejected > rejectPercentage) {
            mapToTransaction[n].status = TransactionStatus.failed;
        }
    }

    function credits() public view returns (uint256) {
        require(
            isMember[msg.sender],
            "Transaction Failed: Only team members can check credits"
        );
        return credit;
    }

    function viewTransaction(uint256 n) public view returns (uint256 amount, string memory transactionStatus) {
        require(IdExist[n], "Transaction not found");
        require(isMember[msg.sender], "You are not a member");

        TransactionRecord memory transaction = mapToTransaction[n];
        return (
            transaction.requestedAmount,
            getStatusString(transaction.status)
        );
    }

    function getStatusString(TransactionStatus _status) internal pure returns (string memory) {
        if (_status == TransactionStatus.pending) {
            return "pending";
        } else if (_status == TransactionStatus.debited) {
            return "debited";
        } else {
            return "failed";
        }
    }

    function transactionStats() public view returns (uint debitedCount, uint pendingCount, uint failedCount) {
        require(isMember[msg.sender], "You are not a member");

        return (debitedCount2, pending, failed);
    }
}