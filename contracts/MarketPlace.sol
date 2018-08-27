pragma solidity ^0.4.17;
//npm install -E openzeppelin-solidity
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

/*  
 * This Online MarketPlace is managed by administrators [user type = Admin (0)].
 * Store owners can register and then manage their stores, products, store inventory and funds.
 * Shoppers can visit stores and purchase items that are available using cryptocurrency wallet
 */

contract MarketPlace is Ownable {       // Using ownable library.

    using SafeMath for uint;            // Using safe math library.
    uint public creationTime = now;     // Time of deployment.
    address owner;                      // Owner of contract and initial admin user.

    constructor() public
     {
        // Create initial administrator account at deployment.
        owner = msg.sender;
        createUser(msg.sender, "Admin", 0, 0, 0);
    }

    modifier ownerRestricted {
        require(owner == msg.sender, "owner restricted feature");
        _;
        // "_;" is replaced by the function body where the modifier is used.
    } 

    function destroyContract() external ownerRestricted {
        // Destroy is limited to owner.
        // This point in the contract, loop through the stores and 
        // return any funds to the wallet of the store owner.
        selfdestruct(owner);
    }

    mapping (address => uint) balance;  /* reference to balance in user wallet */

    // structure for user
    struct user
    {
        uint uid;
        address user;
        string username;
        userType usertype;
        uint256 amount;
        userStatus userstatus;
    }
    enum userType {Admin, Owner}
    enum userStatus {Enabled, Disabled}

    // structure for store
    struct store
    {
        uint sid;
        address owner;
        string name;
        string description;
        uint256 amount;
        string imgsrc;
    }

    // structure for product
    struct product
    {
        uint pid;
        address owner;
        string name;
        string description;
        string imgsrc;
    }

    // structure for store product (a product within a store)
    struct storeproduct
    {
        uint spid;
        uint sid;
        uint pid;
        uint256 price;
        uint256 qty_avail;
        productStatus status;
    }          
    enum productStatus { Available, BackOrder}

    // structure for order (a purchase of a product from a store)
    struct order
    {
        uint oid;
        uint sid;
        uint spid;
        uint pid;
        uint256 price;
        uint256 qty;
    }

    // mappings for ownership of user, store, product, store product and order.
    mapping(address => uint[]) public UserOwnerMap;
    mapping(address => uint[]) public StoreOwnerMap;
    mapping(address => uint[]) public ProductOwnerMap;
    mapping(uint => uint[]) public StoreProductMap;
    mapping(address => uint[]) public OrderOwnerMap;

    /* 
     * the following storage areas are likely stored mostly off chain
     * and only the financial transaction stored in the ledger
     */
    user[] public users;                    /* data storage area for users */
    store[] public stores;                  /* data storage area for stores */
    product[] public products;              /* data storage area for products */
    storeproduct[] public storeproducts;    /* data storage area for products in a store */
    order[] public orders;                  /* data storage area for product purchase from a store */

    // list events and information within them
    event orderCreated (uint oid, uint uid, uint sid, uint pid, uint256 price, uint256 qty, uint timestamp);
    event productCreated(uint pid, address owner, string name, string description, string imgsrc, uint timestamp);
    event productUpdated(uint pid, string name, string description, string imgsrc, uint timestamp);
    event storeCreated(uint sid, address owner, string name, string description, uint256 amount, string imgsrc, uint timestamp);
    event storeUpdated(uint sid, string name, string description, string imgsrc, uint timestamp);
    event storeproductCreated(uint spid, uint sid, uint pid, uint256 price, uint256 qty_avail, uint timestamp);
    event storeproductUpdated(uint spid, uint sid, uint pid, uint256 price, uint256 qty_avail, uint status, uint timestamp);
    event userCreated(uint uid, address user, string username, uint8 usertype, uint256 amount, uint8 userstatus, uint timestamp);
    event userUpdated(uint uid, string username, uint8 usertype, uint8 userstatus, uint timestamp);

    /*
     * The following are the main functional calls that the web (client) front-end uses.
     */

    function createOrder( address _owner, uint _sid, uint _spid, uint _pid, uint256 _price, uint256 _qty) public returns (uint id)
    {
        id = orders.length++;
        order storage newOrder = orders[id];
        newOrder.sid = _sid;
        newOrder.spid = _spid;
        newOrder.pid = _pid;
        newOrder.oid = id;
        newOrder.price = _price;
        newOrder.qty = _qty;
        OrderOwnerMap[_owner].push(id);
        emit orderCreated(id, newOrder.sid, newOrder.spid, newOrder.pid, newOrder.price, newOrder.qty, now);
        return id;
    }
    
    function createProduct( address _owner, string _name, string _description, string _imgsrc ) public returns (uint id)
    {
        id = products.length++;
        product storage newProduct = products[id];
        newProduct.pid = id;
        newProduct.owner = _owner;
        newProduct.name = _name;
        newProduct.description = _description;
        newProduct.imgsrc = _imgsrc;
        ProductOwnerMap[newProduct.owner].push(id);
        emit productCreated(id, newProduct.owner, newProduct.name, newProduct.description, newProduct.imgsrc, now);
        return id;
    }

    function createStore( address _owner, string _name, string _description, uint256 _amount, string _imgsrc ) public returns (uint id)
    {
        id = stores.length++;
        store storage newStore = stores[id];
        newStore.owner = _owner;
        newStore.sid = id;
        newStore.name = _name;
        newStore.description = _description;
        newStore.amount = _amount;
        newStore.imgsrc = _imgsrc;
        StoreOwnerMap[newStore.owner].push(id);
        emit storeCreated(id, newStore.owner, newStore.name, newStore.description, newStore.amount, newStore.imgsrc, now);
        return id;
    }
    
    function createStoreProduct( uint _sid, uint _pid, uint256 _price, uint256 _qty_avail, uint8 _status) public returns (uint id)
    {
        id = storeproducts.length++;
        storeproduct storage newStoreProduct = storeproducts[id];
        newStoreProduct.sid = _sid;
        newStoreProduct.pid = _pid;
        newStoreProduct.spid = id;
        newStoreProduct.price = _price;
        newStoreProduct.qty_avail = _qty_avail;
        newStoreProduct.status = productStatus(_status);
        StoreProductMap[_sid].push(id);
        emit storeproductCreated(id, newStoreProduct.sid, newStoreProduct.pid, newStoreProduct.price, newStoreProduct.qty_avail, now);
        return id;
    }
    
    function createUser( address _user, string _username, uint8 _usertype, uint256 _amount, uint8 _userstatus) public returns (uint id)
    {
        if (UserOwnerMap[_user].length > 0)
        {
            revert("This address is already a registered user.");
        }
        else
        {
            id = users.length++;
            user storage newUser = users[id];
            newUser.user = _user;
            newUser.usertype = userType(_usertype);
            newUser.username = _username;
            newUser.uid = id;
            newUser.amount = _amount;
            newUser.userstatus = userStatus(_userstatus);
            UserOwnerMap[newUser.user].push(id);
            emit userCreated(id, newUser.user, newUser.username, (uint8)(newUser.usertype), newUser.amount, (uint8)(newUser.userstatus), now);
            return id;
        }
    }

    function getUser(uint idx) public view returns (uint, address, string, uint8, uint256, uint8)
    {
        user memory temp = users[idx];
        return (temp.uid, temp.user, temp.username, uint8(temp.usertype), temp.amount, uint8(temp.userstatus));
    }

    function getUserCount() public view returns (uint)
    {
        return users.length;
    }

    function getUserType(address adr) public view returns (uint8)
    {
        uint8 utype = 2;
        uint arrayLength = users.length;

        for (uint i = 0; i < arrayLength; i++) {
            user memory temp = users[i];
            if (temp.user == adr) {
                utype = uint8(temp.usertype);
            }
        }
        return (utype);
    }

    function getOrder(uint idx) public view returns ( uint, uint, uint, uint, uint256, uint256)
    {
        order memory temp = orders[idx];
        return (temp.oid, temp.sid, temp.spid, temp.pid, temp.price, temp.qty);
    } 

    function getOrderCount() public view returns (uint)
    {
        return orders.length;
    } 

    function getProduct(uint idx) public view returns ( uint, address, string, string, string )
    {
        product memory temp = products[idx];
        return (temp.pid, temp.owner, temp.name, temp.description, temp.imgsrc);
    }

    function getProductCount() public view returns (uint)
    {
        return products.length;
    }
    
    function getProductCountForOwner(address _owner) public view returns (uint)
    {
        return ProductOwnerMap[_owner].length;
    }

    function getProductForOwner(address _owner, uint idx) public view returns ( uint, address, string, string, string )
    {
        if (getProductCountForOwner(_owner) >= idx)
        {
            return getProduct(ProductOwnerMap[_owner][idx]);
        }
        else
        {
            revert("product index does not exist for this owner!");
        }
    }

    function getStore(uint idx) public view returns (uint, address, string, string, uint256, string)
    {
        store memory temp = stores[idx];
        return (temp.sid, temp.owner, temp.name, temp.description, temp.amount, temp.imgsrc);
    }

    function getStoreCount() public view returns (uint)
    {
        return stores.length;
    }

    function getStoreCountForOwner(address _owner) public view returns (uint)
    {
        return StoreOwnerMap[_owner].length;
    }

    function getStoreForOwner(address _owner, uint idx) public view returns (uint, address, string, string, uint256, string)
    {
        if (getStoreCountForOwner(_owner) >= idx)
        {
            return getStore(StoreOwnerMap[_owner][idx]);
        }
        else
        {
            revert("store index does not exist for this owner!");
        }
    }

    function getStoreProduct(uint idx) public view returns ( uint, uint, uint, uint256, uint256, uint8)
    {
        storeproduct memory temp = storeproducts[idx];
        return (temp.spid, temp.sid, temp.pid, temp.price, temp.qty_avail, uint8(temp.status));
    }  

    function getStoreProductCount() public view returns (uint)
    {
        return storeproducts.length;
    }

    function getStoreProductCountForStore(uint _sid) public view returns (uint)
    {
        return StoreProductMap[_sid].length;
    }

    // get the Store Product for the store and index position
    function getStoreProductForStore(uint _sid, uint _idx) public view returns ( uint, uint, uint, uint256, uint256, uint)
    {
        if (getStoreProductCountForStore(_sid) >= _idx)
        {
            return getStoreProduct(StoreProductMap[_sid][_idx]);
        }
        else
        {
            revert("store product index does not exist for this store!");
        }
    }  

    function register(address _user, string _username) public returns (uint id)
    {
        return createUser(_user, _username, 1, 0, 0);
    }

    function sellProduct(uint sid, uint spid, uint pid, uint qty) public payable returns (uint)
    {
        // ensure store product id is within array boundary 
        require(spid >= 0 && spid <= storeproducts.length, "store product id does not exist");
        // get store product
        storeproduct memory temp = storeproducts[spid];
        // ensure store id matches 
        require (temp.sid == sid, "store id does not match");
        // ensure at least 1 available 
        require (temp.qty_avail > 0, "insufficient inventory of store product");
        // calculate transaction amount
        uint transAmount = qty * storeproducts[spid].price;
        // ensure buyer has sufficient funds 
        require (balance[msg.sender] >= transAmount, "buyer has insufficient funds");
        // decrease inventory by 1
        storeproducts[spid].qty_avail -= 1;
        // decrease buyers wallet by transaction amount
        balance[msg.sender].sub(transAmount);
        // increase store amount by transaction amount
        stores[sid].amount.add(transAmount);
        // create the order
        return createOrder(msg.sender, sid, spid, pid, temp.price, qty);
    }                       

    function updateProduct( uint _pid, string _name, string _description, string _imgsrc)
        public returns (bool success)
    {
        /* Change to description and imgsrc only */
        products[_pid].description = _description;
        products[_pid].imgsrc = _imgsrc;
        emit productUpdated(_pid, _name, _description, _imgsrc, now);
        return true;
    }

    function updateStore( uint _sid, string _storename, string _description, string _imgsrc)
        public returns (bool success)
    {
        /* Change to description only */
        stores[_sid].description = _description;
        stores[_sid].imgsrc = _imgsrc;
        emit storeUpdated(_sid, _storename, _description, _imgsrc, now);
        return true;
    }

    function updateStoreProduct( uint _spid, uint _sid, uint _pid, uint256 _price, uint256 _qty_avail, uint8 _status)
        public returns (bool success)
    {
        /* Only allow changes to price, qty_avail, and status */
        require(storeproducts[_spid].sid == _sid, "store id mismatch during updateStoreProduct()");
        require(storeproducts[_spid].pid == _pid, "product id mismatch during updateStoreProduct()");
        storeproducts[_spid].price = _price;
        storeproducts[_spid].qty_avail = _qty_avail;
        storeproducts[_spid].status = productStatus(_status);
        emit storeproductUpdated(_spid, _sid, _pid, _price, _qty_avail, (uint8)(_status), now);
        return true;
    }
    
    function updateUser( uint _uid, string _username, uint8 _usertype, uint8 _userstatus)
        public returns (bool success)
    {
        /* Only allow changes to usertype and userstatus */
        users[_uid].usertype = userType(_usertype);
        users[_uid].userstatus = userStatus(_usertype);
        emit userUpdated(_uid, _username, (uint8)(_usertype), (uint8)(_userstatus), now);
        return true;
    }

    function withdraw(uint sid, uint256 amount) public payable returns (bool success)
    {
        // ensure message is from store owner
        require(stores[sid].owner == msg.sender, "must be owner of store");
        // ensure store has requested funds
        require(stores[sid].amount >= amount, "amount greater than store value");
        // decrease stores wallet by transaction amount
        stores[sid].amount.sub(amount);
        // increase callers wallet by transaction amount
        balance[msg.sender].add(amount);
        return true;
    }

    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/ 
    // for details regarding these mathematical functions
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        if (_a == 0) {
            return 0;
        }
        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a / _b;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}