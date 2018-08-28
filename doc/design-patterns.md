# design-patterns.md<br>in the Online Marketplace solution

The marketplace application considered and used a number of design patterns. The following is a detailed list of the design patterns that were implemented:

## Contract Modifiers
When modifiers are added to a Solidity function they extend its functionality, allowing the developer to abstract and extract parts of the code and write functions with fewer conditionals and checks that have to intertwined with state changes.

### Creating a function modifier
The syntax is similar to declaring a function, except it uses the modifier keyword. The underscore on indicates how the original function is changed:

```
modifier assertValueIsOne(uint value) {
  assert(value == 1);
  _; // original function goes at this point
}

function doSomething(uint value)
  assertValueIsOne(value)
{
}
```
**Use cases**
Checking for invariants or conditions using require, revert, or assert accordingly:
```
// For parameterless modifiers, we can omit parenthesis
modifier isAllowed { 
  assert(msg.sender == owner); // contract state
  _;
}
modifier isValidAddress(address target) {
  require(target != 0x0);
  _;
}
modifier isValueBiggerThanZero(uint value) {
  require(value > 0);
  _;
}
function isOwner(address target) constant returns (bool) {
  return target == owner;
}
function simpleFunction(address target)
  isValidAddress(target)
  isValueBiggerThanZero(msg.value)
  isAllowed // omitted parenthesis for parameterless modifiers
  payable
{
    // do something
}
```
**Note** - modifiers are applied to the original function in the order they are presented on the function declaration, i.e: isValidAddress, isValueBiggerThanZero, isAllowed and then payable. Here is an example checking for msg.sender permissions:
```
modifier isOwner {
  assert(owner == msg.sender);
  _;
}

function finalize() isOwner {
  finalized = true;
}
```
Here is an example of raising events before or after a function is called:
```
event StartEvent();
event FinishEvent();
modifier logEvents {
  StartEvent();
  _;
  FinishEvent();
}
function toggle () logEvents {
}

```
## Contract Self Destruction

Marketplace uses the **Contract Self Destruction** pattern for when terminating the contract, This means removing it **forever**  from the blockchain. Once destroyed, it's not possible to invoke functions on the contract and no transactions will be logged in the ledger. Solidity's selfdestruct functionality does two things.

1. It renders the contract useless, effectively deleting the bytecode at that address.
2. It sends all the contract's funds to a target address which in this case is the owner.

The function destroyContract() is responsible for the destruction.

The ownerRestricted modifier was used to only allow the owner of the contract to destroy it and have all of the funds transferred to the Owners account.
```
modifier ownerRestricted {
        require(owner == msg.sender, "restricted feature");
        _;
        // the "_;"!  will
        // be replaced by the actual function
        // body when the modifier is used.
    } 

    function destroyContract() external ownerRestricted {
        selfdestruct(owner);
    }
```
The Contract Self Destruction pattern is used for terminating a contract, which means removing it forever from the blockchain. Once destroyed, it's not possible to invoke functions on the contract and no transactions will be logged in the ledger. This pattern is used for things like dealing with timed contracts or contracts that must be terminated once a milestone has been reached. Here are important notes when dealing with a contract that has been destroyed:

- Transactions will fail
- Any funds sent to the contract will be lost

The modifier was used , to only allow the owner of the contract to destroy it

## Restricting Access

Restricting access is a common pattern for contracts. MarketPlace restricts read access to your contract's state by other contracts. That is actually the default unless you declare make your state variables public. Marketplace uses function modifiers to make these restrictions highly readable.

### Owned
Probably the most used role is Owned, also know as Ownable. It’s role is to keep track of a special role called owner. The ownership game is played like this: Whoever created the contract is its first owner. Whoever is the current owner, can decide who becomes the new owner. That’s it. By itself, ownership doesn’t mean anything. It’s up to the smart contract developer to embellish this role with privileges. The basic contract looks like this:
```
contract Owned {
    address public owner;
    function Owned() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}
```
The solution uses the approve-accept paradigm:
```
    address private ownerCandidate;
    modifier onlyOwnerCandidate() {
        assert(msg.sender == ownerCandidate);
        _;
    }
    function transferOwnership(address candidate) external onlyOwner {
        ownerCandidate = candidate;
    }
    function acceptOwnership() external onlyOwnerCandidate {
        owner = ownerCandidate;
    }
```
The new owner needs to accept the ownership before it receives it. If we accidentally transfered ownership to an invalid address, there is no way this address can accept the ownership. When this happens, we retain ownership and can redo the transfer. Problem solved!

If accidentally send it to a wrong but existing address, and this address accepts ownership before we realize this and redo our transfer, then our contract still ends up in wrong hands! Here are some additional authentication mechanism for the new owner. We can use a one time key:
```
    address private ownerCandidate;
    bytes32 private ownerCandidateKeyHash;

    modifier onlyOwnerCandidate(bytes32 key) {
        assert(msg.sender == ownerCandidate);
        assert(sha3(key) == ownerCandidateKeyHash);
        _;
    }
    function transferOwnership(address candidate, bytes32 keyHash)
        public
        onlyOwner
    {
        ownerCandidate = candidate;
        ownerCandidateKeyHash = keyHash;
    }
    function acceptOwnership(bytes32 key)
        external
        onlyOwnerCandidate(key)
    {
        owner = ownerCandidate;
    }
```
Now, to transfer ownership you generate a random 256 bit key and hash it using web3.sha3. Then we call transferOwnership with the new owner’s address and the hash of the key. We contact the new owner (through any available secure channel), and hand her the key. The new owner calls acceptOwnership providing the key. The contract verifies the key, and if correct, accepts the new owner.

Note: It is important to use a unique key that has not been used before anywhere. Once used, the key is permanently and publicly visible on the blockchain. This is why I used 256 bit random keys. If I were to use a password, someone could brute-force it.

Which one of the two solutions is best depends on your security/usability trade-off. The later adds an additional authentication factor, but it also requires communicating a key over a secure channel, which is huge penalty in the usability field.

### Terminable
Contract Owned often goes hand in with contract Terminable, also known as Mortal. This contract adds a function only owner can trigger, the function to permanently terminate the contract. Any Ether owned by the contract get send to the owner. It looks like this:
```
contract Terminable is Owned {
    function terminate() external onlyOwner {
        selfdestruct(owner);
    }
}
```
This terminates the contract and sends any Ether held by the contract back to the owner.  Ether is no longer the only currency in Ethereum. There are many tokens out there, and smart contracts can own tokens too. If you use the above terminate function on a contract that has tokens, those tokens are permanently lost!

Tokens, as a reminder, tend to have the following interface:
```
contract IERC20Basic {
    function balanceOf(address who) constant public returns (uint);
    function transfer(address to, uint value) public returns (bool ok);
    event Transfer(address from, address to, uint value);
}
```
A contract developer can use these functions to send the tokens to owner on terminate:
```
    function terminate(IERC20Basic[] tokens) external onlyOwner {
        // Transfer tokens to owner
        for(uint i = 0; i < tokens.length; i++) {
            uint256 balance = tokens[i].balanceOf(this);
            tokens[i].transfer(owner, balance);
        }
        // Transfer Ether to owner and terminate contract
        selfdestruct(owner);
    }
```