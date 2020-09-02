
pragma solidity ^0.4.24;

/**
 *  Multi Sender, support TRX & TRC20 Tokens
 * 
*/


library SafeMath {
  function mul(uint a, uint b) internal pure  returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal pure returns (uint) {
    require(b > 0);
    uint c = a / b;
    require(a == b * c + a % b);
    return c;
  }
  function sub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a);
    return c;
  }
  function max64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a >= b ? a : b;
  }
  function min64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a < b ? a : b;
  }
  function max256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a >= b ? a : b;
  }
  function min256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a < b ? a : b;
  }
}

/**
 * @title Multi Sender, support TRX & TRC20 Tokens
 * 
*/

contract ITRC20 {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint value) public;
  event Transfer(address indexed from, address indexed to, uint value);
}

contract TRC20 is ITRC20 {
  function allowance(address owner, address spender) public constant returns (uint);
  function transferFrom(address from, address to, uint value) public;
  function approve(address spender, uint value) public;
  event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * @title Multi Sender, support TRX & TRC20 Tokens
 * 
*/

contract BasicToken is ITRC20 {

  using SafeMath for uint;

  mapping(address => uint) balances;

  function transfer(address _to, uint _value) public{
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }
}

/**
 * @title Multi Sender, support TRX & TRC20 Tokens
 * 
*/

contract StandardToken is BasicToken, TRC20 {
  mapping (address => mapping (address => uint)) allowed;

  function transferFrom(address _from, address _to, uint _value) public {
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
  }

  function approve(address _spender, uint _value) public{
    require((_value == 0) || (allowed[msg.sender][_spender] == 0)) ;
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

/**
 * @title Multi Sender, support TRX & TRC20 Tokens
 * 
*/

contract Ownable {
    address public owner;

    constructor () public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
}

/**
 * @title Multi Sender, support TRX & TRC20 Tokens
 * 
*/

contract MultiSender is Ownable , StandardToken {

    using SafeMath for uint;


    event LogTokenMultiSent(address token,uint256 total);
    event LogGetToken(address token, address receiver, uint256 balance);
    address public receiverAddress;
    uint public txFee = 100000000 ;
    uint public VIPFee = 1000000000 ;

    /* VIP List */
    mapping(address => bool) public vipList;


   /*
  *  Register VIP
  */
  function registerVIP() payable public {
      require(msg.value >= VIPFee);
      require(owner.send(msg.value));
      vipList[msg.sender] = true;
  }

  /*
  *  VIP list
  */
  function addToVIPList(address[] _vipList) onlyOwner public {
    for (uint i =0;i<_vipList.length;i++){
      vipList[_vipList[i]] = true;
    }
  }

  /*
    * Remove address from VIP List by Owner
  */
  function removeFromVIPList(address[] _vipList) onlyOwner public {
    for (uint i =0;i<_vipList.length;i++){
      vipList[_vipList[i]] = false;
    }
   }

    /*
        * Check isVIP
    */
    function isVIP(address _addr) public view returns (bool) {
        return _addr == owner || vipList[_addr];
    }

   


    /*
        * get receiver address
    */
    function getReceiverAddress() public view returns  (address){
        if(receiverAddress == address(0)){
            return owner;
        }

        return receiverAddress;
    }

     /*
        * set vip fee
    */
    function setVIPFee(uint _fee) onlyOwner public {
        VIPFee = _fee;
    }

    /*
        * set tx fee
    */
    function setTxFee(uint _fee) onlyOwner public {
        txFee = _fee;
    }


   function TRXsendSameValue(address[] _to, uint _value) internal {

        uint sendAmount = _to.length.sub(1).mul(_value);
        uint remainingValue = msg.value;

        bool vip = isVIP(msg.sender);
        if(vip){
            require(remainingValue >= sendAmount);
        }else{
            require(remainingValue >= sendAmount.add(txFee)) ;
            owner.transfer(txFee);
            
        }
		require(_to.length <= 255);

		for (uint8 i = 0; i < _to.length; i++) {
		    require(remainingValue >= _value);
			remainingValue = remainingValue.sub(_value);
			require(_to[i].send(_value));
			
		}

	    emit LogTokenMultiSent(0x000000000000000000000000000000000000bEEF,msg.value);
    }

    function TRXSendDifferentValue(address[] _to, uint[] _value) internal {

        uint sendAmount = _value[0];
		uint remainingValue = msg.value;

	    bool vip = isVIP(msg.sender);
        if(vip){
            require(remainingValue >= sendAmount);
        }else{
            require(remainingValue >= sendAmount.add(txFee)) ;
            owner.transfer(txFee);
        }

		require(_to.length == _value.length);
		require(_to.length <= 255);

		for (uint8 i = 0; i < _to.length; i++) {
		    require(remainingValue >= _value[i]);
			remainingValue = remainingValue.sub(_value[i]);
			require(_to[i].send(_value[i]));
			
		}
	    emit LogTokenMultiSent(0x000000000000000000000000000000000000bEEF,msg.value);

    }
    function TRC20SendSameValue(address _tokenAddress, address[] _to, uint _value)  internal {

		uint sendValue = msg.value;
	    bool vip = isVIP(msg.sender);
        if(!vip){
		    require(sendValue >= txFee);
		   owner.transfer(txFee);
        }
		require(_to.length <= 255);
		
		address from = msg.sender;
		uint256 sendAmount = _to.length.sub(1).mul(_value);

        StandardToken token = StandardToken(_tokenAddress);		
		for (uint8 i = 0; i < _to.length; i++) {
		    require( sendValue >= _value);
			token.transferFrom(from, _to[i], _value);
		}

	    emit LogTokenMultiSent(_tokenAddress,sendAmount);

	}

	function TRC20SendDifferentValue(address _tokenAddress, address[] _to, uint[] _value)  internal  {
		uint sendValue = msg.value;
	    bool vip = isVIP(msg.sender);
        if(!vip){
		    require(sendValue >= txFee);
		    owner.transfer(txFee);
        }

		require(_to.length == _value.length);
		require(_to.length <= 255);

        uint256 sendAmount = _value[0];
        StandardToken token = StandardToken(_tokenAddress);
        
		for (uint8 i = 0; i < _to.length; i++) {
		    require(sendValue >= _value[i]);
			token.transferFrom(msg.sender, _to[i], _value[i]);
		}
        emit LogTokenMultiSent(_tokenAddress,sendAmount);

	}
    	function mutiSendTRC20WithSameValue(address _tokenAddress, address[] _to, uint _value)  payable public {
	    TRC20SendSameValue(_tokenAddress, _to, _value);
	    
	}

    /*
        Send coin with the different value by a implicit call method, this method can save some fee.
    */
	function mutiSendTRC20WithDifferentValue(address _tokenAddress, address[] _to, uint[] _value) payable public {
	    TRC20SendDifferentValue(_tokenAddress, _to, _value);
	    
	}

    /*
        Send coin with the different value by a explicit call method
    */
    function multisendToken(address _tokenAddress, address[] _to, uint[] _value) payable public {
	    TRC20SendDifferentValue(_tokenAddress, _to, _value);
	    
    }
    

	function MutiSend_TRX_With_With_DifferentValue(address[] _to, uint[] _value) payable public {
        TRXSendDifferentValue(_to,_value);
	}

	/*
        Send Tron with the same value by a implicit call method
    */

    function MutiSend_TRX_With_SameValue(address[] _to, uint _value) payable public {
		TRXsendSameValue(_to,_value);
	}



}
