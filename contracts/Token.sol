pragma solidity 0.7.0;

import "./IERC20.sol";
import "./IMintableToken.sol";
import "./IDividends.sol";
import "./SafeMath.sol";

contract Token is IERC20, IMintableToken, IDividends {
  // ------------------------------------------ //
  // ----- BEGIN: DO NOT EDIT THIS SECTION ---- //
  // ------------------------------------------ //
  using SafeMath for uint256;
  uint256 public totalSupply;
  uint256 public decimals = 18;
  string public name = "Test token";
  string public symbol = "TEST";
  mapping (address => uint256) public balanceOf;

  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => uint256) private dividends;
  address[] private holders;
  // holder => index+1
  mapping(address => uint256) private holderIndex;
  // ------------------------------------------ //
  // ----- END: DO NOT EDIT THIS SECTION ------ //  
  // ------------------------------------------ //

  // IERC20

  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function transfer(address to, uint256 value) external override returns (bool) {
    require(balanceOf[msg.sender] >= value);
    bool senderWillBeEmpty = balanceOf[msg.sender] == value;
    bool receiverIsNew = balanceOf[to] == 0 && value > 0;
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
    balanceOf[to] = balanceOf[to].add(value);

    if(receiverIsNew){
      _addHolder(to);
    }
    if(senderWillBeEmpty){
      _removeHolder(msg.sender);
    }
    return true;
  }

  function approve(address spender, uint256 value) external override returns (bool) {
    _allowances[msg.sender][spender]=value;
    return true;
  }

  function transferFrom(address from, address to, uint256 value) external override returns (bool) {
    require(balanceOf[from] >= value);
    require(_allowances[from][msg.sender] >= value);
    _allowances[from][msg.sender]= _allowances[from][msg.sender].sub(value);

    bool senderWillBeEmpty = balanceOf[from] == value;
    bool receiverIsNew = balanceOf[to] == 0 && value > 0;

    balanceOf[from] =
        balanceOf[from].sub(value);

    balanceOf[to] =
        balanceOf[to].add(value);

    if(receiverIsNew){
        _addHolder(to);
    }

    if(senderWillBeEmpty){
        _removeHolder(from);
    }

    return true;
  }

  // IMintableToken

  function mint() external payable override {
    require(msg.value>0);
    bool newHolder =
    balanceOf[msg.sender]==0;

    balanceOf[msg.sender] =
        balanceOf[msg.sender].add(msg.value);

    totalSupply =
        totalSupply.add(msg.value);

    if(newHolder){
        _addHolder(msg.sender);
    }

  }

  function burn(address payable dest) external override {
    uint256 amount=balanceOf[msg.sender];
    require(amount>0);
    balanceOf[msg.sender]=0;
    totalSupply=totalSupply.sub(amount);
    _removeHolder(msg.sender);
    dest.transfer(amount);
  }

  // IDividends

  function getNumTokenHolders() external view override returns (uint256) {
    return holders.length;
  }

  function getTokenHolder(uint256 index) external view override returns (address) {
    if(index==0 || index>holders.length){
      return address(0);
    }

    return holders[index-1];
  }

  function recordDividend() external payable override {
    require(msg.value>0);
    if(totalSupply==0){
      return;
    }
    for(uint256 i=0;i<holders.length;i++){
      address h=holders[i];
      uint256 share= msg.value.mul(balanceOf[h]).div(totalSupply);
      dividends[h]=dividends[h].add(share);
    }
  }

  function getWithdrawableDividend(address payee) external view override returns (uint256) {
    return dividends[payee];
  }

  function withdrawDividend(address payable dest) external override {
    uint256 amount=dividends[msg.sender];
    require(amount>0);
    dividends[msg.sender]=0;
    dest.transfer(amount);
  }

  function _addHolder(address account) internal {

      if(holderIndex[account]==0){

          holders.push(account);

          holderIndex[account]=holders.length;
      }
  }

  function _removeHolder(address account) internal {
    if(holderIndex[account]!=0) {

      uint256 index = holderIndex[account]-1;
      uint256 last = holders.length-1;

      if(index != last){
          address lastHolder = holders[last];
          holders[index]=lastHolder;
          holderIndex[lastHolder]=index+1;
      }

      holders.pop();
      holderIndex[account]=0;
    }
  }
}