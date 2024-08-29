// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ElectoralCollegeElection is EIP712, ReentrancyGuard {
    address public owner;
    address public VoterAdmin;
    bool public electionOpen;

    struct Candidate {
        uint256 id;
        string name;
        string party;
        uint256 totalElectoralVotes; // Total electoral votes won by this candidate
    }

    struct State {
        string name;
        uint256 electoralVotes;
        mapping(uint256 => uint256) candidateVotes; // Mapping candidateId to number of votes in that state
        uint256 totalVotes; // Total votes cast in the state
    }

    mapping(uint256 => Candidate) public candidates;
    mapping(string => State) public states;

    mapping(address => bool) public voters;
    mapping(address => string) public voterState; // Stores the state of each voter, it need not be this way

    uint256 public candidateCount;
    uint256 public stateCount;

    event VoteCast(address voter, string state, uint256 candidateId);
    event ElectionClosed();

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not authorized.");
        _;
    }

    modifier electionIsOpen() {
        require(electionOpen, "Election is closed.");
        _;
    }

    modifier hasNotVoted() {
        require(!voters[msg.sender], "You have already voted.");
        _;
    }

    constructor() EIP712("ElectoralCollegeElection", "1") {
        owner = msg.sender;
        electionOpen = true;

        // Add 8 candidates
        addCandidate("Candidate 1", "Party A");
        addCandidate("Candidate 2", "Party B");
        // add the candidates here as per the real world election requirement

        // Add states with electoral votes
        addState("Alabama", 9);
        addState("Alaska", 3);
        addState("Arizona", 11);
        addState("Arkansas", 6);
        addState("California", 54);
        addState("Colorado", 10);
        addState("Connecticut", 7);
        addState("Delaware", 3);
        addState("District of Columbia", 3);
        addState("Florida", 30);
        addState("Georgia", 16);
        addState("Hawaii", 4);
        addState("Idaho", 4);
        addState("Illinois", 19);
        addState("Indiana", 11);
        addState("Iowa", 6);
        addState("Kansas", 6);
        addState("Kentucky", 8);
        addState("Louisiana", 8);
        addState("Maine", 4);
        addState("Maryland", 10);
        addState("Massachusetts", 11);
        addState("Michigan", 15);
        addState("Minnesota", 10);
        addState("Mississippi", 6);
        addState("Missouri", 10);
        addState("Montana", 4);
        addState("Nebraska", 5);
        addState("Nevada", 6);
        addState("New Hampshire", 4);
        addState("New Jersey", 14);
        addState("New Mexico", 5);
        addState("New York", 28);
        addState("North Carolina", 16);
        addState("North Dakota", 3);
        addState("Ohio", 17);
        addState("Oklahoma", 7);
        addState("Oregon", 8);
        addState("Pennsylvania", 19);
        addState("Rhode Island", 4);
        addState("South Carolina", 9);
        addState("South Dakota", 3);
        addState("Tennessee", 11);
        addState("Texas", 40);
        addState("Utah", 6);
        addState("Vermont", 3);
        addState("Virginia", 13);
        addState("Washington", 12);
        addState("West Virginia", 4);
        addState("Wisconsin", 10);
        addState("Wyoming", 3);
    }

    function addCandidate(string memory _name, string memory _party) private {
        candidates[candidateCount] = Candidate(
            candidateCount,
            _name,
            _party,
            0
        );
        candidateCount++;
    }

    function addState(string memory _name, uint256 _electoralVotes) private {
        State storage newState = states[_name];
        newState.name = _name;
        newState.electoralVotes = _electoralVotes;
        stateCount++;
    }

    function vote(
        string memory _stateName,
        uint256 _candidateId,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) public electionIsOpen hasNotVoted {
        require(
            verify(_stateName, _candidateId, msg.sender, nonce, deadline, signature) == owner, // Assuming `owner` is the expected signer
            "Invalid signature"
        );
        require(_candidateId < candidateCount, "Invalid candidate.");
        require(states[_stateName].electoralVotes > 0, "Invalid state.");

        // Record vote for the candidate in the voter's state
        states[_stateName].candidateVotes[_candidateId]++;
        states[_stateName].totalVotes++;

        // Mark the voter as having voted
        voters[msg.sender] = true;
        voterState[msg.sender] = _stateName;

        emit VoteCast(msg.sender, _stateName, _candidateId);
    }

    function verify(
        string memory state,
        uint256 candidateId,
        address voter,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) public view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "Vote(string state,uint256 candidateId,address voter,uint256 nonce,uint256 deadline)"
                    ),
                    keccak256(bytes(state)),
                    candidateId,
                    voter,
                    nonce,
                    deadline
                )
            )
        );
        return ECDSA.recover(digest, signature);
    }

    function getLeadingCandidate(string memory _stateName)
        public
        view
        returns (string memory, uint256)
    {
        State storage state = states[_stateName];
        require(state.totalVotes > 0, "No votes cast in this state.");

        uint256 leadingCandidateId;
        uint256 highestVotes = 0;

        for (uint256 i = 0; i < candidateCount; i++) {
            if (state.candidateVotes[i] > highestVotes) {
                highestVotes = state.candidateVotes[i];
                leadingCandidateId = i;
            }
        }

        // Return the name of the leading candidate and their current vote count in that state
        Candidate memory leadingCandidate = candidates[leadingCandidateId];
        return (
            leadingCandidate.name,
            state.candidateVotes[leadingCandidateId]
        );
    }

    function closeElection() public onlyOwner {
        require(electionOpen, "Election is already closed.");
        electionOpen = false;

        emit ElectionClosed();
    }

    // Function to check the total electoral votes won by any candidate
    function getCandidate(uint256 _candidateId)
        public
        view
        returns (
            string memory,
            string memory,
            uint256
        )
    {
        require(_candidateId < candidateCount, "Invalid candidate.");
        Candidate memory c = candidates[_candidateId];
        return (c.name, c.party, c.totalElectoralVotes);
    }

    // Function to check the current vote count of a candidate in a state
    function getStateVotes(string memory _stateName, uint256 _candidateId)
        public
        view
        returns (uint256)
    {
        require(states[_stateName].electoralVotes > 0, "Invalid state.");
        return states[_stateName].candidateVotes[_candidateId];
    }
}
