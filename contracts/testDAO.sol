pragma solidity ^0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";


// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma

contract DAO {
    // Members of the DAO
    struct Member {
        address addr;
        uint256 shares;
        uint256 reputation;
        bool active;
    }

    // Proposal for the DAO to vote on
struct Proposal {
    address proposer;
    string description;
    uint256 value;
    uint256 votingDeadline;
    bool approved;
}

// Mapping from addresses to member structures
mapping(address => Member) public members;

// Array of all proposals
Proposal[] public proposals;

// The minimum quorum required for voting to take place (in percentage)
uint256 public quorum;

// The minimum percentage of votes required for a proposal to pass (in percentage)
uint256 public majority;

// The minimum reputation required to propose a new proposal
uint256 public proposalReputation;

// The minimum reputation required to vote
uint256 public votingReputation;

// The total number of shares in the DAO
uint256 public totalShares;

// The minimum amount of time that must pass between proposing and voting on a proposal (in seconds)
uint256 public proposalVotingPeriod;

// The address of the contract owner
address public owner;

// The current number of active members in the DAO
uint256 public numMembers;

// The current number of proposals in the DAO
uint256 public numProposals;

// The address of the KubixToken contract
address public KUBIX_TOKEN_ADDRESS;

// Flag to check if the contract has been initialized
bool public initialized;

// Events for logging
event NewMember(address member);
event ProposalCreated(uint256 proposalId);
event ProposalVoted(uint256 proposalId, bool approved);
event FundsWithdrawn(address recipient, uint256 amount);

constructor() public {
    owner = msg.sender;
    initialized = false;
}

function initialize(uint256 _quorum, uint256 _majority, uint256 _proposalReputation, uint256 _votingReputation, uint256 _proposalVotingPeriod, address _KUBIX_TOKEN_ADDRESS) public {
    require(!initialized, "Contract has already been initialized");
    require(msg.sender == owner, "Only the owner can initialize the contract");

    quorum = _quorum;
    majority = _majority;
    proposalReputation = _proposalReputation;
    votingReputation = _votingReputation;
    proposalVotingPeriod = _proposalVotingPeriod;
    KUBIX_TOKEN_ADDRESS = _KUBIX_TOKEN_ADDRESS;

    // Issue a new token on the Polygon network called KUBIX
    SafeERC20 kubixToken = SafeERC20(KUBIX_TOKEN_ADDRESS);
    kubixToken.issue("KUBIX", msg.sender, 1000000);

    initialized = true;
}

//


    // Function to add a new member to the DAO
    function addMember(address _member) public {
        require(_member != address(0), "Cannot add 0x0 address as a member");
        require(!members[_member].active, "Member already exists");
        require(msg.sender == owner, "Only the owner can add new members");

        Member memory newMember;
        newMember.addr = _member;
        newMember.shares = 1;
        newMember.reputation = 0;
        newMember.active = true;

        members[_member] = newMember;
        totalShares++;
        numMembers++;

        emit NewMember(_member);
    }

    // Function to propose a new proposal to the DAO
    function propose(string memory _description, uint256 _value) public {
        require(members[msg.sender].reputation >= proposalReputation, "Sender does not have sufficient reputation to propose");
        require(_value > 0, "Cannot propose a proposal with a value of 0 or less");

        Proposal memory newProposal;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.value = _value;
        newProposal.votingDeadline = now + proposalVotingPeriod;
        newProposal.approved = false;

        proposals.push(newProposal);
        numProposals++;

        emit ProposalCreated(numProposals - 1);
    }

    // Function to vote on a proposal
    function vote(uint256 _proposalId, bool _approve) public {
        require(_proposalId < numProposals, "Invalid proposal ID");
        require(now <= proposals[_proposalId].votingDeadline, "Voting deadline has passed");
        require(members[msg.sender].reputation >= votingReputation, "Sender does not have sufficient reputation to vote");

        // Check if the sender has already voted on this proposal
        uint256 index;
        for (index = 0; index < proposals[_proposalId].voters.length; index++) {
            if (proposals[_proposalId].voters[index] == msg.sender) {
                break;
            }
        }
        require(index == proposals[_proposalId].voters.length, "Sender has already voted on this proposal");

        // Add the sender's vote to the proposal
        proposals[_proposalId].votes.push(_approve);
        proposals[_proposalId].voters.push(msg.sender);

        // Check if the proposal has reached the required quorum and majority to pass
        uint256 numVotes = proposals[_proposalId].votes.length;
        uint256 numApprove = 0;
        for (index = 0; index < numVotes; index++) {
            if (proposals[_proposalId].votes[index]) {
                numApprove++;
            }
        }
        if ((numVotes / totalShares) * 100 >= quorum && (numApprove / numVotes) * 100 >= majority) {
            proposals[_proposalId].approved = true;
        }

        emit ProposalVoted(_proposalId, proposals[_proposalId].approved);
    }

    // Function to withdraw funds from the DAO
    function withdraw(uint256 _value) public {
        require(_value <= address(this).balance, "Insufficient funds in the contract");
        require(proposals[numProposals - 1].approved, "The last proposal must be approved before funds can be withdrawn");

        msg.sender.transfer(_value);

        emit FundsWithdrawn(msg.sender, _value);
    }
        

        
        
        // Function to vote on a proposal using a direct democracy system, where 51% is the required majority
    function voteDirectDemocracy(uint256 _proposalId, bool _approve) public {
        require(_proposalId < numProposals, "Invalid proposal ID");
        require(now <= proposals[_proposalId].votingDeadline, "Voting deadline has passed");
        require(members[msg.sender].reputation >= votingReputation, "Sender does not have sufficient reputation to vote");

        // Check if the sender has already voted on this proposal
        uint256 index;
        for (index = 0; index < proposals[_proposalId].voters.length; index++) {
            if (proposals[_proposalId].voters[index] == msg.sender) {
                break;
            }
        }
        require(index == proposals[_proposalId].voters.length, "Sender has already voted on this proposal");

        // Add the sender's vote to the proposal
        proposals[_proposalId].votes.push(_approve);
        proposals[_proposalId].voters.push(msg.sender);

        // Calculate the total number of votes and the number of votes in favor of the proposal
        uint256 numVotes = proposals[_proposalId].votes.length;
        uint256 numApprove = 0;
        for (index = 0; index < numVotes; index++) {
            if (proposals[_proposalId].votes[index]) {
                numApprove++;
            }
        }

        // Check if the proposal has received a majority of votes in favor
        if ((numApprove / numVotes) * 100 >= 51) {
            proposals[_proposalId].approved = true;
        }

        emit ProposalVoted(_proposalId, proposals[_proposalId].approved);
    }
    
    
    
    
    
    
    
    // Function to vote on a proposal using a weighted voting system, where votes are proportional to the number of tokens a member holds
    // Function to vote on a proposal using a weighted voting system, where votes are proportional to the number of KUBIX a member holds in their public address
    function voteWeightedKubix(uint256 _proposalId, bool _approve) public {
        require(_proposalId < numProposals, "Invalid proposal ID");
        require(now <= proposals[_proposalId].votingDeadline, "Voting deadline has passed");
        require(members[msg.sender].reputation >= votingReputation, "Sender does not have sufficient reputation to vote");

        // Check if the sender has a balance of KUBIX in their public address
        require(KubixToken(KUBIX_TOKEN_ADDRESS).balanceOf(msg.sender) > 0, "Sender does not have a balance of KUBIX in their public address");

        // Add the sender's vote to the proposal, weighted by the number of KUBIX they hold in their public address
        proposals[_proposalId].votes.push(_approve ? KubixToken(KUBIX_TOKEN_ADDRESS).balanceOf(msg.sender) : 0);
        proposals[_proposalId].voters.push(msg.sender);

        // Calculate the total number of votes and the number of votes in favor of the proposal
        uint256 numVotes = proposals[_proposalId].votes.length;
        uint256 numApprove = 0;
        for (uint256 index = 0; index < numVotes; index++) {
            numApprove += proposals[_proposalId].votes[index];
        }

        // Check if the proposal has received a majority of votes in favor
        if ((numApprove / numVotes) * 100 >= 51) {
            proposals[_proposalId].approved = true;
        }

        emit ProposalVoted(_proposalId, proposals[_proposalId].approved);
    }

}

    // ERC20 token contract to be used on the Polygon network
contract ERC20KubixToken is SafeERC20 {
    string public name = "Kubix Token";
    string public symbol = "KUBX";
    uint8 public decimals = 18;
    uint256 public totalSupply;



mapping(address => uint256) public balanceOf;

function mint(address _to, uint256 _value) public {
    require(msg.sender == owner, "Only the contract owner can mint new tokens");
    require(_value > 0, "Cannot mint 0 or less tokens");
    totalSupply += _value;
    balanceOf[_to] += _value;
}

function transfer(address _to, uint256 _value) public {
    require(balanceOf[msg.sender] >= _value, "Insufficient balance");
    require(_value > 0, "Cannot transfer 0 or less tokens");

    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
}

}