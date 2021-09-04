pragma solidity ^0.4.24;

contract FundRaising {
    mapping( address => uint ) public contributors;
    uint public minimumContributtion;
    uint public numberOfContributors;
    address public admin;
    uint public deadline;
    uint public goal;
    uint public raisedAmount = 0;
    
    struct Request{
        string description;
        uint value;
        address recipient;
        bool complete;
        uint numberOfVoters;
        mapping(address => bool) voters;
    }
    
    Request[] public requests;
    
    event ContributeEvent(address sender, uint value);
    event CreateRequestEvent(string description, address sender, uint value);
    event MakePayementEvent(address recipient, uint value);
    
    constructor(uint _goal, uint _deadline) public{
        deadline = now + _deadline;
        goal = _goal;
        admin = msg.sender;
        minimumContributtion = 1 wei;
    }
    
    function contribute() public payable{
        require(now < deadline);
        require(msg.value >= minimumContributtion);
        
        if(contributors[msg.sender] == 0) numberOfContributors++;
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
        
        emit ContributeEvent(msg.sender, msg.value);
    }
    
    function getBlance() public view returns(uint){
        return address(this).balance;
    }
    
    function getRefund() public {
        require(now > deadline);
        require(raisedAmount < goal);
        require(contributors[msg.sender] > 0);
        
        address recipient = msg.sender;
        uint value = contributors[recipient];
        
        recipient.transfer(value);
        contributors[recipient] = 0;
    }
    
    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }
    
    function createRequest(string _description, address _recipient, uint _value) public onlyAdmin{
        Request memory newRequest = Request({
            description: _description,
            value: _value,
            recipient:  _recipient,
            complete:  false,
            numberOfVoters:  0
        });
        requests.push(newRequest);
        
        emit CreateRequestEvent(_description, _recipient, _value);
    }
    
    function voter(uint index) public{
        Request storage thisRequest = requests[index];
        require(contributors[msg.sender] > 0);
        require(thisRequest.voters[msg.sender] == false);
        
        thisRequest.voters[msg.sender] = true;
        thisRequest.numberOfVoters++;
        
        
    }
    
    function makePayment(uint index) public onlyAdmin{
        Request storage thisRequest = requests[index];
        require(thisRequest.complete == false);
        require(thisRequest.numberOfVoters > numberOfContributors / 2);
        
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.complete = true;
        
        emit MakePayementEvent(thisRequest.recipient, thisRequest.value);
    }
}