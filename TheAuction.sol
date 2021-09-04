pragma solidity ^0.4.24;

contract auctionCreator{
    address[] public auctions;
    
    function creationAuction() public{
        address newAuction = new Auction(msg.sender);
        auctions.push(newAuction);
    }
}

contract Auction{
    address public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;
    
    enum State {Started, Running, Ended, Canceled}
    State public auctionState;
    
    uint public highestBid;
    uint public highestBiddingBid;
    address public highestBidder;
    
    mapping(address => uint) public bids;
    
    uint public bidIncrement;
    
    constructor(address creator) public{
        owner = creator;
        startBlock = block.number;
        endBlock = startBlock + 2; // number of block in one week
        ipfsHash = "hash123xz";
        bidIncrement = 1000000000000000000;
        auctionState = State.Running;
    }
    
    modifier notOwner(){
        require(msg.sender != owner);
        _;
    }
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    modifier afterStart(){
        require(block.number >= startBlock);
        _;
    }
    modifier endStart(){
        require(block.number <= endBlock);
        _;
    }
    
    function min(uint a, uint b) pure internal returns(uint){
        if(a < b) return a;
        else return b;
    }
    
    function placeBid() public payable notOwner afterStart endStart returns(bool){
        require(auctionState == State.Running);
        require(msg.value >= 0.0001 ether);
        
        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBid);
        bids[msg.sender] = currentBid;
        
        if(currentBid <= bids[highestBidder]){
            highestBiddingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        }else{
            highestBiddingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = msg.sender;
        }
        return true;
    }

    function cancelAuction() public onlyOwner {
        auctionState = State.Canceled;
    }
    
    function finalizeAuction() public{
       //the auction has been Ended or Canceled
       require(auctionState == State.Canceled || block.number > endBlock); 
       
       require(msg.sender == owner || bids[msg.sender] > 0);
       
       address recipient;
       uint value;
       
       if(auctionState == State.Canceled){ //canceled not ended
           recipient = msg.sender;
           value = bids[msg.sender];
       }else{//ended not canceled
           if(msg.sender == owner){ //the owner finalizes the auction
               recipient = owner;
               value = highestBiddingBid;
           }else{//another user finalizes the auction
               if (msg.sender == highestBidder){
                   recipient = highestBidder;
                   value = bids[highestBidder] - highestBiddingBid;
               }else{//this is neiher the owner nor the highest bidder
                   recipient = msg.sender;
                   value = bids[msg.sender];
               }
           }
       }
       
       //sends value to the recipient
       recipient.transfer(value);
        
    }

        

    
}