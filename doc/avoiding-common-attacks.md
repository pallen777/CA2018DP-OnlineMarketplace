# avoiding-common-attacks.md<br>in the Online Marketplace solution

This document describes the measures that were taken and/or considered to ensure that blockchain contracts are not susceptible to common attacks.

## Known Attacks

The following is a list of known attacks which were reviewed during development of the Online Marketplace. While every effort was made to implement these patterns, time constraints limited the implementation of the complete list.

### Integer Overflow and Underflow

A solution to this problem was implemented using Open Zeppelin for Solidity library. This library must be installed into the Node environment via the following command:
```
npm install -E openzeppelin-solidity
```
The following imports were used in the MarketPlace.sol contract:

```
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
```

The following clause was incorporated into the contract:

```
    using SafeMath for uint;
```

This library is used when transferring Ether:

```
mapping (address => uint256) public balanceOf;

// INSECURE approach
function moveValue(address _to, uint256 _value) {
    // Check if sender has sufficient balance
    require(balanceOf[msg.sender] >= _value);

    // Add and subtract new balances
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
}

// SECURE approach
function moveValue(address _to, uint256 _value) {
    // Check if sender has sufficient balance and for overflows
    require(balanceOf[msg.sender] >= _value && balanceOf[_to] + _value >= balanceOf[_to]);

    // Add and subtract new balances
    balanceOf[msg.sender].sub(_value);
    balanceOf[_to].add(_value);
}
```

If a uint reaches the maximum value (2^256) it will cycle back to zero, this is known as overflow. The above secure approach checks for that situation. This may or may not be relevant to all solidity solutions as is depends on the functionality being implemented. Developers must consider if the uint value has an opportunity to approach such a large number. The developer must also take into consideration how the uint variable changes state, and who has authority to change it. If a user can call functions which update the uint value, it's more suseptible to this form of attack. If only an administrator can change the value, it might be safe from attack. Also, its unlikely that this condition will ever be met if a user can only call functions that increment the value by 1. In this case, it would take a very long time to get to this condition and therefore very unlikely. The same considerations need to be made for underflow. If a uint is made to be less than zero, it will cause an underflow and get set to its maximum value.

Underflow in Depth: Storage Manipulation
Underflow might affect Solidity storage. Here is a simplified version:
contract UnderflowManipulation {
    address public owner;
    uint256 public manipulateMe = 10;
    function UnderflowManipulation() {
        owner = msg.sender;
    }

    uint[] public bonusCodes;

    function pushBonusCode(uint code) {
        bonusCodes.push(code);
    }

    function popBonusCode()  {
        require(bonusCodes.length >=0);  // this is a tautology
        bonusCodes.length.sub(1); // an underflow can be caused here
    }

    function modifyBonusCode(uint index, uint update)  { 
        require(index < bonusCodes.length);
        bonusCodes[index] = update; // write to any index less than bonusCodes.length
    }

}

#### Array Storage
```
// This is a possible fix to avoid underflows
uint[] public array;

    function pop() public {
        // This is a possible fix to avoid underflows
        require(array.length > 0);
        array.length.sub(1);
    }
```

## Race Conditions

Calling external contracts can be an issue as they can take over the control flow, and make changes to data that the calling function wasn't expecting. Onine Marketplace does not reference external contracts.

### Reentrancy
The first version of this bug to be noticed involves functions that could be called repeatedly, before the first invocation of the function was finished. This may cause the different invocations of the function to interact in destructive ways. In the withdraw functionality which was not perfected we would apply the following techniques:
``` 
// INSECURE
mapping (address => uint) private userBalances;

function withdrawBalance() public {
    uint amountToWithdraw = userBalances[msg.sender];
    require(msg.sender.call.value(amountToWithdraw)());
    // At this point, the caller's code is executed, and can call withdrawBalance again
    userBalances[msg.sender] = 0;
}
```
Since the user's balance is not set to 0 until the very end of the function, the second (and later) invocations will still succeed, and will withdraw the balance over and over again. A very similar bug was one of the vulnerabilities in the DAO attack.
To avoid the problem we use send() instead of call.value()(). This will prevent any external code from being executed. Another way to prevent this attack is to make sure you don't call an external function until you've done all the internal work you need to do:
```
mapping (address => uint) private userBalances;

function withdrawBalance() public {
    uint amountToWithdraw = userBalances[msg.sender];
    userBalances[msg.sender] = 0;
    require(msg.sender.call.value(amountToWithdraw)()); 
    // The user's balance is already 0, so future invocations won't withdraw anything
}
```
### Cross-function Race Conditions

An attacker may also be able to do a similar attack using two different functions that share the same state.
```
// INSECURE
mapping (address => uint) private userBalances;

function transfer(address to, uint amount) {
    if (userBalances[msg.sender] >= amount) {
       userBalances[to] += amount;
       userBalances[msg.sender] -= amount;
    }
}

function withdrawBalance() public {
    uint amountToWithdraw = userBalances[msg.sender];
    require(msg.sender.call.value(amountToWithdraw)()); // At this point, the caller's code is executed, and can call transfer()
    userBalances[msg.sender] = 0;
}
```
In this case, the attacker calls transfer() when their code is executed on the external call in withdrawBalance. Since their balance has not yet been set to 0, they are able to transfer the tokens even though they already received the withdrawal. 

### Pitfalls in Race Condition Solutions
We would finish all internal work first, and only then calling the external function. This rule, if followed carefully, will allow us to avoid race conditions. For example, the following is insecure:
```
// INSECURE
mapping (address => uint) private userBalances;
mapping (address => bool) private claimedBonus;
mapping (address => uint) private rewardsForA;

function withdraw(address recipient) public {
    uint amountToWithdraw = userBalances[recipient];
    rewardsForA[recipient] = 0;
    require(recipient.call.value(amountToWithdraw)());
}

function getFirstWithdrawalBonus(address recipient) public {
    require(!claimedBonus[recipient]); // Each recipient should only be able to claim the bonus once

    rewardsForA[recipient] += 100;
    withdraw(recipient); // At this point, the caller will be able to execute getFirstWithdrawalBonus again.
    claimedBonus[recipient] = true;
}
```
Even though getFirstWithdrawalBonus() doesn't directly call an external contract, the call in withdraw() is enough to make it vulnerable to a race condition. You therefore need to treat withdraw() as if it were also untrusted.
```
mapping (address => uint) private userBalances;
mapping (address => bool) private claimedBonus;
mapping (address => uint) private rewardsForA;

function untrustedWithdraw(address recipient) public {
    uint amountToWithdraw = userBalances[recipient];
    rewardsForA[recipient] = 0;
    require(recipient.call.value(amountToWithdraw)());
}

function untrustedGetFirstWithdrawalBonus(address recipient) public {
    require(!claimedBonus[recipient]); // Each recipient should only be able to claim the bonus once

    claimedBonus[recipient] = true;
    rewardsForA[recipient] += 100;
    untrustedWithdraw(recipient); // claimedBonus has been set to true, so reentry is impossible
}
```
### Transaction-Ordering Dependence (TOD) / Front Running
The prior examples of race conditions involving the attacker executing malicious code within a single transaction. The following are a different type of race condition inherent to Blockchains: the fact that the order of transactions themselves (within a block) is easily subject to manipulation. This can be troublesome for things like decentralized markets, where a transaction to buy some tokens can be seen, and a market order implemented before the other transaction gets included. Protecting against this is difficult, as it would come down to the specific contract itself. 

### DoS with (Unexpected) revert
Consider a simple auction contract:
```
// INSECURE
contract Auction {
    address currentLeader;
    uint highestBid;

    function bid() payable {
        require(msg.value > highestBid);

        require(currentLeader.send(highestBid)); // Refund the old leader, if it fails then revert

        currentLeader = msg.sender;
        highestBid = msg.value;
    }
}
```
When it tries to refund the old leader, it reverts if the refund fails. This means that a malicious bidder can become the leader while making sure that any refunds to their address will always fail. In this way, they can prevent anyone else from calling the bid() function, and stay the leader forever. Another example is when a contract may iterate through an array to pay users (e.g., supporters in a crowdfunding contract). It's common to want to make sure that each payment succeeds. If not, one should revert. The issue is that if one call fails, you are reverting the whole payout system, meaning the loop will never complete. No one gets paid because one address is forcing an error.
```
address[] private refundAddresses;
mapping (address => uint) public refunds;

// bad
function refundAll() public {
    for(uint x; x < refundAddresses.length; x++) { // arbitrary length iteration based on how many addresses participated
        require(refundAddresses[x].send(refunds[refundAddresses[x]])) // doubly bad, now a single failure on send will hold up all funds
    }
}
```