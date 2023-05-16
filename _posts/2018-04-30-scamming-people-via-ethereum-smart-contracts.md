---
layout: post
title: Scamming people via Ethereum smart contracts
subtitle: Ever tried the game 'guess the word'? Well, the smart contract version isn't that fun to play.
description: Strange features in the Solidity programming language allow scammers to create faulty smart contracts (honeypots) on the ethereum blockchain.
keywords: ethereum, blockchain, smart, contract, faulty, scam, scamming, hack, steal, money, guess, the, word, game, honeypot
author: Tijme Gommers
include_in_header: false
include_in_footer: false
show_in_post_list: true
robots: index, follow
---

**[TL;DR]** Using a 'feature' in the Solidity programming language it is possible to create smart contracts on the Ethereum blockchain that look completely legit; however, everyone that sends money to the contract can never get it back due to that 'feature'.

<hr>

Alright, lets dive right into it. The code snippet below is an [Ethereum](https://www.ethereum.org/){:target="_blank"}{:rel="noopener noreferrer"} [smart contract](https://en.wikipedia.org/wiki/Smart_contract){:target="_blank"}{:rel="noopener noreferrer"} written in [Solidity](https://solidity.readthedocs.io/){:target="_blank"}{:rel="noopener noreferrer"}. If you do not understand any of those terms, click on the links to get more information.

Before you try to work out how the contract works, let me tell you it's a scam contract that contains a Solidity 'feature' that causes unexpected behaviour. Below the code snippet you can find an extensive [explanation](#explanation) of the contract. The actual contract can be found on [Etherscan](https://etherscan.io/address/0x9823e4e4f4552cd84720dabbd6fb2c7b67066c6c#code){:target="_blank"}{:rel="noopener noreferrer"}.

{% highlight solidity %}
pragma solidity ^0.4.23;

contract NumberBetweenZeroAndTen {

    uint256 private secretNumber;
    uint256 public lastPlayed;
    address public owner;
    
    struct Player {
        address addr;
        uint256 ethr;
    }
    
    Player[] players;
    
    constructor() public {
        // On construct set the owner and a random secret number
        owner = msg.sender;
        shuffle();
    }
    
    function guess(uint256 number) public payable {
        // Guessing costs a minimum of 1 ether 
        require(msg.value >= 1 ether);
        
        // Guess must be between zero and ten
        require(number >= 0 && number <= 10);
        
        // Update the last played date
        lastPlayed = now;
        
        // Add player to the players list
        Player player;
        player.addr = msg.sender;
        player.ethr = msg.value;
        players.push(player);
        
        // Payout if guess is correct
        if (number == secretNumber) {
            msg.sender.transfer(this.balance);
        }
        
        // Refresh the secret number
        shuffle();
    }
    
    function shuffle() internal {
        // Randomly set secretNumber with a value between 1 and 10
        secretNumber = uint8(sha3(now, block.blockhash(block.number-1))) % 10 + 1;
    }

    function kill() public {
        // Enable owner to kill the contract after 24 hours of inactivity
        if (msg.sender == owner && now > lastPlayed + 24 hours) {
            selfdestruct(msg.sender);
        }
    }
}
{% endhighlight %}

### Explanation

I'll first explain how one would expect the contract to work.

1. Someone constructs the contract.
    1. The variable `owner` is set to the sender's address.
    2. The method `shuffle` is called.
        1. The `shuffle` method sets `secretNumber` to a random number from 0 to 10.
2. A l33t h4x0r finds the smart contract by syncing the chain or by searching Etherscan.
    1. He finds out that you can win money if you know `secretNumber`.
    2. There's a pretty high chance he guesses the number right after a few times, but instead he decides to do something else.
    3. Although the `secretNumber` is a private variable, he knows you can get it by [reading](https://medium.com/aigang-network/how-to-read-ethereum-contract-storage-44252c8af925){:target="_blank"}{:rel="noopener noreferrer"} the contract's storage.
    4. So he reads the storage and finds out the `secretNumber` is 6. **Bingo!**
    5. He calls the `play` method with 6 as `number` argument (and with 1.2 ether) and expects to get the ether from the contract.

Please note the `payable` keyword from the `play` method. It enables people to send ether to the method, which will then automatically be stored in the contract.

The big question is; did the l33t h4x0r outplay the contract's creator/owner?

### The scam

Well, that 'someone' that constructed the contract wasn't just someone. It was a scammer who used a 'feature' from Solidity to mislead everyone who played the game. There are at least three ways why people fall for this.

1. One can keep calling the `play` method and bet on it that he eventually wins.
2. One knows that the `secretNumber` is not really random, since it's made up of the date and the previous block hash.
    1. The person calculates the `secretNumber` by getting the variables it was made up of.
    2. The person calls the `play` method using that number.
3. One knows how to read the contract's storage.
    1. The person reads the location of the `secretNumber` from the storage.
    2. The person calls the `play` method using the number on that location.

Unfortunately none of these methods work.

### The 'feature'

The scammer paid very much attention to the Solidity documentation.

The local variables of struct, array or mapping type reference storage [by default](https://solidity.readthedocs.io/en/latest/frequently-asked-questions.html#what-is-the-memory-keyword-what-does-it-do){:target="_blank"}{:rel="noopener noreferrer"}. This means they are stored in the contract's storage.

The Solidity documentation also states that;

>  The type of the local variable `player` is `Player` (stored in storage), but since storage is not dynamically allocated, it has to be assigned from a state variable before it can be used. So no space in storage will be allocated for `player`, but instead it functions only as an alias for a pre-existing variable in storage.

> What will happen is that the compiler interprets `player` as a storage pointer and will make it point to the storage slot 0 by default. This has the effect that `secretNumber` (which resides at storage slot 0) is modified by `players.push(player)`.

Please note that I modified the variable names in the quotes above to match the contract.

So to elaborate on this a little bit more. `Player player;` points to storage slot 0 because it's an uninitialized storage variable. The `uint256 private secretNumber;` also points to storage slot 0 because it's the first variable that is declared in the contract (and it's also set on construct). This means whenever you change something in `player`, you will change the `secretNumber`.

In this case `player.addr = msg.sender;` is executed right after the `Player player;` line. This means storage slot 0 gets set to `msg.sender`. This leads to the fact that whenever you get `secretNumber` from the storage after that line of code was executed, it will give you the value of `msg.sender`.

### But wait, there's more

Why don't we just call the `play` method with `msg.sender` as `number` argument.

In theory this could work. But keep in mind that the `play` function requires the number to be 10 or lower.

{% highlight solidity %}
require(number >= 0 && number <= 10);
{% endhighlight %}

This means that when your address (`msg.sender`) is 10 or lower you can win the ether in this contract.

In reality the chance is very very very little that your address is 10 or lower, and therefore you can (almost) never win ether from this contract.

### Where does the ether go?

There is a nice `kill` method that enables the contract's creator to destruct the contract whenever the last played date is 24 hours ago. The self destruct sends all the money in the contract back to the owner of the contract (the attacker).