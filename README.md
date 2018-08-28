# Online Marketplace Project

## What does the Online Marketplace project do?

Marketplace is a DApp (decentralized application) that allows store owners to create stores and products and add products to stores and make them for sale to shoppers. When the contract is deployed an initial 'administrator' user is created and set to the address of the deployer. This administrator can update the user type (Admin, Owner) and status of users (Enabled, Disabled). All user access and permissioning is determined by the currently logged in user within the MetaMask plugin. A MetaMask user (except the Admin user) can register as a store owner. Store owners can create one or more stores. Store owners can also create one or more products.  For each store, the store owner can add from their list of products and set the amount of inventory and price for that store. Any other type of user is designated as a Shopper (shoppers logged in to a MetaMask account) for the marketplace. The Shopping menu shows a list of stores and their description. They can then choose a store and see a list of the products available in that store. A Shopper can then choose to purchase a product by clicking on the Buy button within the store. When they purchase a product, an order is created, the store product quantity available is decreased and the Shopper MetaMask wallet is debited by the store price of item purchased. The store owner's account is also credited for the price of the purchased item. In the marketplace contract there are entities and relationship represented by solidity structures. These include users, stores, products, store products and orders.

![](doc/storage-entities.png "Storage Entities")

## Part A. How to set up the Online Marketplace

Online Marketplace is a truffle project that can run on a local development server. The project requires that Truffle is installed. See https://truffleframework.com/docs/truffle/getting-started/installation for details.

Note that the following documents cover additional aspects of the submmitted solution:
1. [Design Patterns](doc/design-patterns.md)
2. [Avoiding Common Attacks](doc/avoiding-common-attacks.md)

### Step 1: Compilation

Open a command prompt, navigate to the downloaded project and run the following command:
```
$ truffle compile
```

### Step 2: Start local blockchain

In order to migrate and run the contract, you must first create a local private blockchain network. To do so, open a second command prompt and run the following command:

```
$ ganache-cli
```

The above command will among other things, output a list of available accounts, their private keys and a mnemonic phrase that should be copied and used later. Here is an example output from the ganache-cli tool

```
Ganache CLI v6.1.6 (ganache-core: 2.1.5)

Available Accounts
==================
(0) 0x5e2f231b3b4259318952d6f2ad8e760e012adc6c (~100 ETH)
(1) 0x71e795a63086d7309bd67e2273b9adb53439501f (~100 ETH)
(2) 0xe2cc5214cc6de2ab2de047aafaca0917cca5ba97 (~100 ETH)
(3) 0xbc2c9fd8e470a63a4fe941499ec3561dd6c9a466 (~100 ETH)
(4) 0xc4876ceb9a422e6def9b8f2a8253e30e28a7b04c (~100 ETH)
(5) 0x88ded0c10d6e17d2b6f7354fe8e2f51d8a221e75 (~100 ETH)
(6) 0x9883444398a425e39156b6576aeb7edc29aefaea (~100 ETH)
(7) 0x94ff526d09f36d40a20f691edc6e43034e921c66 (~100 ETH)
(8) 0x54a6e9d7c55c1085a1208ebe7b682ed14633b16f (~100 ETH)
(9) 0xcc7568a071b362e80a13928ad3119c38788ebb2c (~100 ETH)

Private Keys
==================
(0) 0x33c0d28f1aa003a15014751836bc5a8010f568834c0c2dfd52d24a72da248bc6
(1) 0xb6c1ae58b0142131e4c7b33c1529683912d93cd08b989f075341bebedbb05595
(2) 0x60dc031b342865f1b178ba778ed9bbbaa42dfee42dcc2f8feba7e99d009132a2
(3) 0x461082941c2fe835ce8bfcde88812edd8056131eed7897aec7e4e9de8a12aed5
(4) 0xecaf399a16c62b998422b8c1a10f46ec122074c0cf1d946277e31ac3639f817a
(5) 0xb781687f935e2ccb8e13fd32dab61680a4cd6f60bfa8c077418305e7a855b895
(6) 0x03c58c519835cea63b3d8a3562c63f705a2eb176cfe814fa9ac659afe6404745
(7) 0x9489ab50860dad9b3c4b4d39d6d9cdc9096c860304a95ed7b52b13d7f9bb243a
(8) 0x5025a7e54101ee479d22c16d1b189bf2c8d3f857fcdc7ae4356ad917b623c9c3
(9) 0xf51755e633ebf41f7140ba24cd2681a24b8bcc85cb1c8352a46ea0810c3d469c

HD Wallet
==================
Mnemonic:      action mouse age muscle park seed bread sick scatter odor text aspect
Base HD Path:  m/44'/60'/0'/0/{account\_index}

Gas Price
==================
20000000000

Gas Limit
==================
6721975

Listening on 127.0.0.1:8545
```

### Step 3: Migrate and deploy contract

The next step is to migrate the Online Marketplace contracts to the local private blockchain listening on port 8545 (see ganache-cli output). Type the following into a command prompt for the root directory of the download:
```
$ truffle deploy
```
The output from the above command should look something like the following:
```
Using network 'development'.

Running migration: 1\_initial\_migration.js
  Deploying Migrations...
  ... 0x4a92ab2558e78a6446d74a51a591a05452e3d4d361e3235c6c067711064bdb7d
  Migrations: 0xfaef9045d7874b3ddeeb0e948ec5a8d8ee7e2ab6
Saving successful migration to network...
  ... 0xad9b39d760269a138baec9cbb4acc67724f4d6b2fbcaba67e525f635749b5612
Saving artifacts...
Running migration: 2\_deploy\_contracts.js
  Deploying MarketPlace...
  ... 0xd979a94a665d67dae52bf5c9473b977f3b19e478ad74b9556bdb0c11746e7086
  MarketPlace: 0x39ce8c031646d72585f0d5e2a3250926163cf14e
Saving successful migration to network...
  ... 0x605ba73c588754e20d9522440c4cdb6c21ee0f0cce1a1f4274b7d3b318b389f7
Saving artifacts...
```
### Step 4: Run tests

All of the test cases for the Online Marketplace are held in the test directory. From a command prompt in the root of the downloaded directory, run the following command:

```
$ truffle test
```

The output from the above command should look something like the following:

```
Using network 'development'.

Compiling ./contracts/MarketPlace.sol...
Compiling ./test/TestMarketPlace.sol...
Compiling openzeppelin-solidity/contracts/math/SafeMath.sol...
Compiling openzeppelin-solidity/contracts/ownership/Ownable.sol...
Compiling truffle/Assert.sol...
Compiling truffle/DeployedAddresses.sol...

  TestMarketPlace
    ✓ testUserCount (105ms)
    ✓ testCreateStore (215ms)
    ✓ testStoreCount (85ms)
    ✓ testCreateProduct (191ms)
    ✓ testProductCount (67ms)
    ✓ testCreateStoreProduct (208ms)
    ✓ testStoreProductCount (116ms)
    ✓ testSellProduct (308ms)
    ✓ testWithdraw (358ms)

  9 passing (2s)
  0 failing
```

### Step 5: Start the web application

To do so, open a third command prompt and run the following command:

```
$ npm run dev
```

The above command will create something like the following output:

```
\> marketplace@1.0.0 dev /Users/pallen/wip-consensys/CA2018DP-OnlineMarketplace
\> lite-server
\*\* browser-sync config \*\*
{ injectChanges: false,
  files: ['./\*\*/\*.{html,htm,css,js}'],
  watchOptions: { ignored: 'node\_modules' },
  server:
   { baseDir: ['./src', './build/contracts'],
     middleware: [[Function], [Function] ] } }
[Browsersync] Access URLs:
---------------------------------------
       Local: http://localhost:3000
    External: http://192.168.10.101:3000
---------------------------------------
          UI: http://localhost:3001
 UI External: http://192.168.10.101:3001
---------------------------------------
[Browsersync] Serving files from: ./src
[Browsersync] Serving files from: ./build/contracts
[Browsersync] Watching files...
```

At this point, a browser should open at [http://localhost:3000](http://localhost:3000) and you will see a screen that looks like this:

![](doc/home-logged-out.png "Home page and metamask (logged out)")

## Part B: How to use the Online Marketplace

Now that you have the Online Marketplace compiled, deployed and running on a local blockchain network, you are now ready to try out the user interface.

### Establishing MetaMask

In order to use the Online Marketplace you will need to install and set up the MetaMask browser plugin. MetaMask will be used to select accounts from the list of the ten (10) accounts that are automatically generated in the local blockchain network. These accounts will be used in the sections below to represent an Administrators, Store Owners and Shoppers. To start with, open the MetaMask browser plugin and, if necessary, log out of any current wallet before proceeding to the restore from wallet seed function.

#### Restore MetaMask from Wallet Seed

Open the MetaMask plugin and click link that says ```Import using account seed phrase```. This will open the plugin home page for MetaMask, again click on the ```Import using account seed phrase``` link. This will open the Restore your Account with Seed Phrase page. Enter in the mnemonic that was output from ganache-cli in Step 2 above (in example above this phrase is: ```action mouse age muscle park seed bread sick scatter odor text aspect```). Enter the New Password and Confirm Password fields and click Restore button. 

![](doc/metamask-restore.png "Metamask restore your account with seed phrase")

Once you've restored the wallet, make sure you are still pointing to the local network by clicking on the dropdown labeled "Private Network" and re-selecting Localhost 8545.

#### Setup MetaMask accounts

Once you've restored from the Wallet Seed in prior step, you will have a single account set up (named Account 1 by default) that uses the 1st address of the ten (10) accounts set up by ganache-cli in Step 2 above. Now you go ahead and create three (3) more accounts (for a total of 4). Each time that you click on Create Account within the MetaMask plugin, it will create an account and associate it with the next available account within the list of ten (10) known accounts.

![](doc/metamask-4-accounts.png "Metamask with 4 accounts created")

Once you've create three (3) more accounts, choose Account 1 again, then open the home page and you will see that you are an Administrator. Click on Users menu item and you will see the admin user that was created by contract constructor.

![](doc/user-list1.png "User list 1")

Go back to MetaMask plugin and choose Account 2, then open the home page and you will see that you are classified as a Shopper. Click on Register menu item and fill in the user name and click on the Register button. MetaMask will prompt you to confirm the transaction. Once complete, refresh the home page and you will now see that you are classified as a Store Owner.

![](doc/register-owner1.png "register 1st owner")

Go back to MetaMask plugin and choose Account 3, then open the home page and again you will see that you are classified as a Shopper. Click on Register menu item and fill in the user name and click on the Register button. MetaMask will prompt you to confirm the transaction. Once complete, refresh the home page and you will now see that you are classified as another Store Owner.

![](doc/register-owner2.png "register 2nd owner")

Go back to the home page http://localhost:3000 and click on the the Users menu item to see the list of current users. It should look something like this:

![](doc/user-list2.png "User list 2")

Logon as each Owner (switch MetaMask Account) and Create/Display Stores

![](doc/store-list.png "Store list")

Logon as Owner and create a Product

![](doc/product-create.png "Product create")

List the Products

![](doc/product-list.png "Product create")

Create StoreProducts, one product selected and amounts filled in.
![](doc/store-product-list1.png "Store product list 1")

Display Store Products, with multiple products added to store.
![](doc/store-product-list2.png "Store product list 2")

Now switch to Shopper, login as Account 4 (create account) and click on Shopping link

Img: Shopping.html showing stores
![](doc/shopping-stores.png "Shopping stores")

Enter a store and buy a Product

![](doc/shopping-store-products.png "Shopping store products")

Now log in as Account 2, open the home page http://localhost:3000 and click on Stores, select a store and press the Withdraw button. This will withdraw the funds from the store and place them into the wallet of the logged in user (Account 2).