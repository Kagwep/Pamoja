// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BusinessVerificationContract {
    address public owner;
    uint public contractBalance; // To keep track of the contract's balance
    uint private nextBusinessId = 1;
    uint256 private voteCounter;

    // Define your BusinessListing struct and storage as you've provided earlier.
    struct BusinessListing {
        uint businessId;
        string name;
        address owner;
        uint fundAmountRequest;
        address payable businessAddress;
        uint shareAmount;
    }

    struct Verification {
        uint256 businessId;
        string verificationFile;
        bool isVerified;
        uint256 voteCount; // Number of votes for verification
    }

    struct DevelopmentRoadmap {
        uint256 businessId;
        string DevelopmentRoadmapFile;
        bool isVerified;
        uint256 voteCount; // Number of votes for verification
        uint256 targetVote;
    }

    struct Regular {
        uint256 businessId;
        string votePurpose;
        bool isVerified;
        uint256 voteCount; // Number of votes for verification
        uint256 targetVote;
    }

    struct Fund {
        uint businessId;
        uint vote;
    }

    struct ShareReturn {
        uint businessId;
        uint shareReturnAmount;
        string agreementFile;
    }

    struct PaySchedule {
        uint businessId;
        uint shareAmount;
        uint paymentDate;
    }

    struct Vote {
        uint256 voteId;
        uint256 option;
        uint256 businessId;
        bool hasVoted;
    }

    enum VoteType { Regular, Verification, DevelopmentRoadmap }

    mapping(uint => BusinessListing) public businessListings;
    mapping(uint => Verification) public businessVerifications;
    mapping(uint => Fund) public businessFunds;
    mapping(uint => uint) public businessVotes;
    mapping(uint => ShareReturn) public shareReturns;
    mapping(uint => PaySchedule) public paySchedules;
    mapping(address => mapping(VoteType => Vote)) votes;
    mapping(uint256 => DevelopmentRoadmap) public developmentRoadmaps;
    mapping(uint256 => Regular) public regularVotes;


    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action");
        _;
    }

    event Voted(uint256 indexed voteId, address indexed voter, uint256 option, uint256 businessId, VoteType voteType);
    event BusinessVerified(uint256 businessId);
    event DevelopmentRoadmapVerified(uint256 businessId);
    event RegularVerified(uint256 businessId);

    event BusinessFunded(uint businessId, uint amount);
    event BusinessPassed(uint businessId);
    event SharePaid(uint businessId, uint amount);
    event ShareReduced(uint businessId, uint amount);
    event Voted(address indexed voter, uint256 option);

    function createBusinessListing(string memory _name, address payable _businessAddress, uint _fundAmountRequest) external {
        uint newBusinessId = nextBusinessId;
        nextBusinessId++;

        businessListings[newBusinessId] = BusinessListing(newBusinessId, _name, msg.sender, _fundAmountRequest, _businessAddress, 100);
    }


    function vote(uint256 selectedOption, uint256 businessId, VoteType voteType) public {
        require(voteType == VoteType.Regular || voteType == VoteType.Verification || voteType == VoteType.DevelopmentRoadmap, "Invalid vote type");

        voteCounter++;
        votes[msg.sender][voteType] = Vote({
            voteId: voteCounter,
            option: selectedOption,
            businessId: businessId,
            hasVoted: true
        });

        emit Voted(voteCounter, msg.sender, selectedOption, businessId, voteType);

        if (voteType == VoteType.Verification) {
            require(
                !votes[msg.sender][VoteType.Verification].hasVoted &&
                votes[msg.sender][VoteType.Verification].businessId != businessId,
                "You have already voted for Verification for this business."
            );
            businessVerifications[businessId].voteCount++;
            if (businessVerifications[businessId].voteCount >= calculateVerificationThreshold(businessId)) {
                businessVerifications[businessId].isVerified = true;
                emit BusinessVerified(businessId);
            }
        }else if (voteType == VoteType.DevelopmentRoadmap) {
            require(
                !votes[msg.sender][VoteType.DevelopmentRoadmap].hasVoted &&
                votes[msg.sender][VoteType.DevelopmentRoadmap].businessId != businessId,
                "You have already voted for DevelopmentRoadmap for this business."
            );
            developmentRoadmaps[businessId].voteCount++;
            if (developmentRoadmaps[businessId].voteCount >= developmentRoadmaps[businessId].targetVote) {
                developmentRoadmaps[businessId].isVerified = true;
                emit DevelopmentRoadmapVerified(businessId);
            }
        } else if (voteType == VoteType.Regular) {
            require(
                !votes[msg.sender][VoteType.Regular].hasVoted &&
                votes[msg.sender][VoteType.Regular].businessId != businessId,
                "You have already voted for Regular for this business."
            );
            regularVotes[businessId].voteCount++;
            if (regularVotes[businessId].voteCount >= regularVotes[businessId].targetVote) {
                regularVotes[businessId].isVerified = true;
                emit RegularVerified(businessId);
            }
        }
    }

    function calculateVerificationThreshold(uint256 businessId) public view returns (uint256) {
        BusinessListing storage business = businessListings[businessId];
        return business.fundAmountRequest / 10; // Adjust the formula as needed
    }

    function verifyBusiness(uint _businessId, string memory _verificationFile) external onlyOwner {
        require(businessListings[_businessId].owner != address(0), "Business ID does not exist");
        businessVerifications[_businessId] = Verification(_businessId, _verificationFile, true);
    }

    function fundBusinessByOwner(uint _businessId, uint _amount) external onlyOwner {
        require(_amount > 0, "Funding amount must be greater than 0");
        require(businessListings[_businessId].owner != address(0), "Business ID does not exist");

        businessListings[_businessId].fundAmountRequest += _amount;
        businessListings[_businessId].businessAddress.transfer(_amount);
        emit BusinessFunded(_businessId, _amount);
    }

    function depositToContract() external payable {
        require(msg.value > 0, "You must send some ether to deposit to the contract");
        contractBalance += msg.value;
    }

    function voteForBusiness(uint _businessId, uint _vote) external {
        businessFunds[_businessId].businessId = _businessId;
        businessFunds[_businessId].vote = _vote;

        businessVotes[_businessId] += 1;

        if (businessVotes[_businessId] >= 5) {
            emit BusinessPassed(_businessId);
        }
    }

    function createShareReturn(uint _businessId, uint _shareReturnAmount, string memory _agreementFile) external onlyOwner {
        shareReturns[_businessId] = ShareReturn(_businessId, _shareReturnAmount, _agreementFile);
    }

    function payShare(uint _businessId, uint _amount) external {
        require(businessListings[_businessId].owner == msg.sender, "You don't own this business");
        require(businessListings[_businessId].shareAmount > 0, "No share to pay");

        if (businessListings[_businessId].shareAmount <= _amount) {
            businessListings[_businessId].shareAmount = 0;
            emit SharePaid(_businessId, businessListings[_businessId].shareAmount);
        } else {
            businessListings[_businessId].shareAmount -= _amount;
            emit SharePaid(_businessId, _amount);
        }
    }

    function createPaySchedule(uint _businessId, uint _shareAmount, uint _paymentDate) external onlyOwner {
        paySchedules[_businessId] = PaySchedule(_businessId, _shareAmount, _paymentDate);
    }

    function reduceShareBySchedule(uint _businessId) external {
        uint currentTimestamp = block.timestamp;

        require(paySchedules[_businessId].businessId == _businessId, "No pay schedule found for this business");
        require(paySchedules[_businessId].paymentDate <= currentTimestamp, "Payment date not reached");

        businessListings[_businessId].shareAmount = paySchedules[_businessId].shareAmount;
        emit ShareReduced(_businessId, paySchedules[_businessId].shareAmount);

        // Remove the pay schedule
        delete paySchedules[_businessId];
    }
}
