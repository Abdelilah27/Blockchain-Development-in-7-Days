pragma solidity ^0.4.24;

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);

    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Crypto is ERC20Interface{
    string public name = "Crypto";
    string public symbol = "CRY";
    uint public decimal = 0;
    uint public supply;
    address public founder;
    
    mapping(address => uint) public balances;
    event Transfer(address indexed from, address indexed to, uint tokens);
    mapping(address => mapping(address => uint)) allowed;
    
    constructor() public {
        supply = 1000;
        founder = msg.sender;
        balances[founder] = supply;
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining){
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) public returns (bool success){
        require(balances[msg.sender] >= tokens && tokens > 0);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success){
        require(allowed[from][to] >= tokens);
        require(balances[from] >= tokens);
        balances[from] -= tokens;
        balances[to] += tokens;
        allowed[from][to] -= tokens;
        return true;
    }
    
    function totalSupply() public view returns (uint){
        return supply;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint balance){
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint tokens) public returns (bool success){
        require(balances[msg.sender] >= tokens && tokens > 0);
        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
}


contract CryptoIco is Crypto{
    address public admin;
    address public deposit;
    
    uint public  cryptoAmount = 0.01 ether;
    
    uint public hardCap = 300 ether;
    
    uint public raisedAmount;
    
    uint public salesStart = now;
    uint public salesEnd = salesStart + 60;
    uint public coinTrade = salesEnd + 20;
    
    uint public maximumInvest = 5 ether;
    uint public minimumInvest = 0.01 ether;
    
    enum State {beforeStart, running, afterEnd, halted}
    State public icoState;
    
    event InvestEvent(address from, uint value, uint tokens);
    
    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }
    
    constructor(address _deposit) public{
        deposit = _deposit;
        admin = msg.sender;
        icoState = State.beforeStart;
    }
    
    function halt() public{
        icoState = State.halted;
    }
    
    function restart() public{
        icoState = State.running;
    }
    
    function changeDepositAddress(address _new) public onlyAdmin{
        deposit = _new;
    }
    
    function getCurrentState() public view returns(State){
        if(icoState == State.beforeStart || block.timestamp < salesStart) return State.beforeStart;
        if(icoState == State.running || (block.timestamp >= salesStart && block.timestamp < salesEnd) ) return State.running;
        if(icoState == State.afterEnd || block.timestamp >= salesEnd ) return State.afterEnd;
        if(icoState == State.halted) return State.halted;

    }
    
    function invest() payable public returns(bool){
        icoState = getCurrentState();
        require(icoState == State.running);
        require(msg.value >= minimumInvest && msg.value <= maximumInvest);
        
        uint tokens = msg.value / cryptoAmount;
        
        require(raisedAmount + msg.value <= hardCap);
        
        raisedAmount += msg.value;
        
        balances[msg.sender] += tokens;
        balances[founder] -= tokens;
        
        deposit.transfer(msg.value);
        
        emit InvestEvent(msg.sender, msg.value, tokens) ;
        
        return true;
    }
    
    function () payable external {
        invest();
    }
    
    function transfer(address to, uint tokens) public returns (bool success){
        require(block.timestamp > coinTrade);
        super.transfer(to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success){
        require(block.timestamp > coinTrade);
        super.transferFrom(from, to, tokens);
        return true;
    }
    
    function burn() public returns(bool success){
        require(getCurrentState() == State.afterEnd);
        balances[founder] = 0;
        return true;
    }
    
}
