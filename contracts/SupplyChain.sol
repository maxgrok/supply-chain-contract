/*
    This exercise has been updated to use Solidity version 0.5
    Breaking changes from 0.4 to 0.5 can be found here: 
    https://solidity.readthedocs.io/en/v0.5.0/050-breaking-changes.html
*/

pragma solidity ^0.5.0;

contract SupplyChain {

  // state variables
  address owner;

  uint public skuCount;
  
  mapping(uint => Item) items;

  
  enum State {ForSale, Sold, Shipped, Received} 
  
  struct Item {
    string name;
    uint sku;
    uint price; 
    State state; 
    address payable seller;
    address payable buyer;
  }

  //Events
  event LogForSale(uint sku);
  event LogSold(uint sku);
  event LogShipped(uint sku);
  event LogReceived(uint sku);

  //Modifiers
  modifier isOwner {
    require(msg.sender == owner);
    _;
  }
  modifier isSeller(uint _sku) {
    require(items[_sku].seller == msg.sender);
    _;
  }

  modifier isBuyer(uint _sku){
    require(msg.sender == items[_sku].buyer);
    _;
  }

  modifier verifyCaller (address _address) { require (msg.sender == _address); _;}
  
  modifier checkValue(uint _sku) {
    //refund them after pay for item (why it is before, _ checks for logic before func)
    _;
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    items[_sku].buyer.transfer(amountToRefund);
  }

  modifier forSale(uint _sku) {
    require(uint(items[_sku].state) >= 0);
    _;
  }

  modifier sold(uint _sku){
    require(uint(items[_sku].state) >= 1);
    _;
  }

  modifier shipped(uint _sku) {
    require(uint(items[_sku].state) >= 2);
    _;
  }

  modifier received(uint _sku) {
    require(uint(items[_sku].state) >= 3);
    _;
  }

  //Contructor 
  constructor() public {
       owner = msg.sender;
       skuCount = 0;
  }

  //Functions
  function addItem(string memory _name, uint _price) public returns(bool){
    items[skuCount] = Item({name: _name, sku: skuCount, price: _price, state: State.ForSale, seller: msg.sender, buyer: address(0)});
    emit LogForSale(skuCount);
    skuCount = skuCount + 1;
    return true;
  }

  function buyItem(uint sku)
    public payable forSale(sku)
  {
    require(msg.value >= items[sku].price);
    Item storage item = items[sku];

    address payable seller = item.seller;
    item.buyer = msg.sender;
    uint price = item.price;
    seller.transfer(price);
    emit LogSold(sku);
    item.state = State.Sold;
  }

  function shipItem(uint sku) sold(sku) isSeller(sku)
    public
  {
    Item storage item = items[sku];
    item.state = State.Shipped;
    emit LogShipped(sku);
  }

  function receiveItem(uint sku) shipped(sku) isBuyer(sku)
    public
  {
    Item storage item = items[sku];
    item.state = State.Received;
    emit LogReceived(sku);
  }

  function fetchItem(uint _sku) public view returns (string memory name, uint sku, uint price, uint state, address seller, address buyer) {
    name = items[_sku].name;
    sku = items[_sku].sku;
    price = items[_sku].price;
    state = uint(items[_sku].state);
    seller = items[_sku].seller;
    buyer = items[_sku].buyer;
    return (name, sku, price, state, seller, buyer);
  }

}
