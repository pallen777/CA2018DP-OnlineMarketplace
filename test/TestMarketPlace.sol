pragma solidity ^0.4.17;
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/MarketPlace.sol";
contract TestMarketPlace {

    // Structure for a user
    struct user
    {
        uint uid;
        address user;
        string username;
        userType usertype;
        uint256 amount;
    }
    enum userType {Admin, Owner}

    // define store entity
    struct store
    {
        uint sid;
        address owner;
        string name;
        string description;
        uint256 amount;
    }

    // define product entity
    struct product
    {
        uint pid;
        address owner;
        string name;
        string description;
        string imgsrc;
    }

    struct storeproduct
    {
        uint spid;
        uint sid;
        uint pid;
        uint256 price;
        uint256 qty_avail;
        productStatus status;
    }          
    enum productStatus {Available, OutOfStock}

    struct order
    {
        uint oid;
        // uint uid;
        uint sid;
        uint spid;
        uint pid;
        uint256 price;
        uint256 qty;
    }    

    // Get handle to the currently deployed contract
    MarketPlace marketPlace = MarketPlace(DeployedAddresses.MarketPlace());

    // Test the getUserCount() function
    function testUserCount() public {
        // At deployment an admin user should be created
        uint expected = 1;
        Assert.equal(marketPlace.getUserCount(), expected, "User count is expected to be 1");
    }

    // Test the createStore() function
    function testCreateStore() public {
        address owner = marketPlace.owner();
        string memory name = "Store 1";
        string memory description = "This is a store";
        uint256 amount = 10;
        string memory imgsrc = "images/store1.png";
        uint sid = marketPlace.createStore(owner, name, description, amount, imgsrc);
        Assert.equal(marketPlace.getStoreCount(), sid+1, "store id count did not increment");
    }

    // Test the getStoreCount() function
    function testStoreCount() public {
        uint expected = 1;
        Assert.equal(marketPlace.getStoreCount(), expected, "Store count is expected to be 1");
    }

    // Test the createProduct() function
    function testCreateProduct() public {
        address _owner = marketPlace.owner();
        string memory _name = "Product 1";
        string memory _description = "Ths is a product";
        string memory _imgsrc = "images/product1.png";
        uint pid = marketPlace.createProduct(_owner, _name, _description, _imgsrc);
        Assert.equal(marketPlace.getProductCount(), pid+1, "product id count did not increment");
    }

    // Test the getProductCount() function
    function testProductCount() public {
        uint expected = 1;
        Assert.equal(marketPlace.getProductCount(), expected, "Product count is expected to be 1");
    }

    // Test the createStoreProduct() function
    function testCreateStoreProduct() public {
        uint id = 0;
        Assert.equal(marketPlace.getStoreCount(), id+1, "store id count did not increase");
        Assert.equal(marketPlace.getProductCount(), id+1, "product id count did not increase");
        uint sid = 0;
        uint pid = 0;
        uint256 price = 1;
        uint256 qty_avail = 10;
        uint8 status = 0;
        uint spid = marketPlace.createStoreProduct(sid, pid, price, qty_avail, status);
        Assert.equal(marketPlace.getStoreProductCount(), spid+1, "store product id count did not increase");
    }

    // Test the getStoreProductCount() function
    function testStoreProductCount() public {
        uint expected = 1;
        Assert.equal(marketPlace.getStoreProductCount(), expected, "Store product count is expected to be 1");
    }

    // Test the sellProduct() function
    function testSellProduct() public {
        uint id = 0;
        Assert.equal(marketPlace.getStoreCount(), id+1, "store id count did not increase");
        Assert.equal(marketPlace.getProductCount(), id+1, "product id count did not increase");
        Assert.equal(marketPlace.getStoreProductCount(), id+1, "store product id count did not increase");
        uint sid = 0;
        uint pid = 0;
        uint spid = 0;
        uint256 qty = 1;
        uint oid = marketPlace.sellProduct(sid, spid, pid, qty);
        Assert.equal(marketPlace.getOrderCount(), oid+1, "order id count did not increase");
    }

    // Test the withdraw() function
    function testWithdraw() public {
        uint sid = 0;
        Assert.equal(marketPlace.getStoreCount(), sid+1, "store id count did not increase");
        uint256 amount = 1;
        bool result = marketPlace.withdraw(sid, amount);
        bool expected = true;
        Assert.equal(result, expected, "withdrawal did not succeed");
    }

}