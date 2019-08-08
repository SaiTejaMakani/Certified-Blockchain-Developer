pragma solidity ^0.5.1;

contract admined{
    
    address public admin;
    
    constructor() public {
        admin = msg.sender;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    
    function transferAdminship(address newAdmin) onlyAdmin public {
        admin = newAdmin;
    }
    
}

contract TCoin{
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    string public standard = "TCoin v1.0";
    string public name;
    string public symbol;
    uint8 public decimal;
    uint256 public totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    constructor(uint256 initialSupply, string memory tokenName, string memory tokenSymbol, uint8 decimalUnits) public{
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimal = decimalUnits;
    }
    
    function transfer(address _to, uint256 _value) public{
        require(balanceOf[msg.sender] > _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
    }
    
    function approval(address _sender, uint256 _value) public returns(bool success){
        allowance[msg.sender][_sender] = _value;
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns (bool success){
        require(balanceOf[_from] > _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        require(_value < allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
}

contract TCoinAdvanced is admined, TCoin {
    
    mapping ( address => bool) public frozenAccount;
    uint public buyPrice;
    uint public sellPrice;
    
    event FrozenFund( address target, bool frozen);
    
    constructor(uint256 initialSupply, string memory tokenName, string memory tokenSymbol, uint8 decimalUnits, address centralAdmin) TCoin(0, tokenName, tokenSymbol, decimalUnits) public {
        totalSupply = initialSupply;
        if(centralAdmin != address(0))
            admin = centralAdmin;
        else
            admin = msg.sender;
        balanceOf[admin] = initialSupply;
    }

    function mintToken(address target, uint256 minedAmount) onlyAdmin public {
        balanceOf[target] += minedAmount;
        totalSupply += minedAmount;
        emit Transfer(address(0), address(this), minedAmount);
        emit Transfer(address(this), target, minedAmount);
    }
    
    function freezeAccount(address target, bool freeze) onlyAdmin public {
        frozenAccount[target] = freeze;
        emit FrozenFund(target, freeze);
    }
    
    function transfer(address _to, uint256 _value) public{
        require(balanceOf[msg.sender] > _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        require(!frozenAccount[msg.sender]);
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns (bool success){
        require(balanceOf[_from] > _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        require(_value < allowance[_from][msg.sender]);
        require(!frozenAccount[_from]);
        
        allowance[_from][msg.sender] -= _value;
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyAdmin public{
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    
    function buy() payable public{
        uint256 amount = ((msg.value/1 ether))/buyPrice;
        require(balanceOf[address(this)] > amount);
        balanceOf[msg.sender] += amount;
        balanceOf[address(this)] -= amount;
        emit Transfer(address(this), msg.sender, amount);
    }
    
    function sell(uint256 amount) public{
        require(balanceOf[msg.sender] > amount);
        balanceOf[address(this)] += amount;
        balanceOf[msg.sender] -= amount;
        require(msg.sender.send(amount * sellPrice * 1 ether));
    }
    
    function giveBlockReward() public{
        balanceOf[block.coinbase] += 1;
    }
    
    bytes32 public currentChallange;
    uint public timeOfLastProof;
    uint public difficulty = 10**32;
    
    function proofOfWork(uint nonce) public{
        bytes32 n = sha256(abi.encodePacked(nonce, currentChallange));
        require(n > bytes32(difficulty));
        uint timeSinceLastBlock = (now - timeOfLastProof);
        require(timeSinceLastBlock > 5 seconds);
        balanceOf[msg.sender] += timeSinceLastBlock/ 60 seconds;
        difficulty = difficulty * 10 minutes / timeOfLastProof + 1;
        timeOfLastProof = now;
        currentChallange = sha256(abi.encodePacked(nonce, currentChallange, blockhash(block.number-1)));
    }  
}
