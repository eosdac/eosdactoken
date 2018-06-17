# Token/Member Contract

This contract creates the currency and also give a means to say whether an eosDAC account holder is a member.  A member is classified as a token holder who has registered and agreed to the membership agreement.

Once this contract is launched we will issue a quantity of eosDAC tokens equivalent to the number of issued ERC-20 tokens minus the number never collected.

https://github.com/EOSIO/eos/blob/master/contracts/eosio.token/eosio.token.abi#L4

## create
Standard currency create action, will mint a certain number of tokens and credit them to the account mentioned

if `transferred_locked` is set `true` the contract will prevent all transfers except from the token creator.

## issue

Standard currency action. Issue tokens and send them to the account specified (standard currency method).  This will require a privileged account.

## unlock

Unlock a token to allow transfers from accounts other than the token creator. The parameter passed in must be a standard asset in the form of "1000.0000 ABC". Although the amount component eg. 1000.000 is ignored for the logic it is required for the format of an asset parameter.

***This can only be done to `unlock` a token and cannot be reversed to lock a token again.***

## transfer

Standard currency contract function to facilitate transfer.

## memberadd

This is called to add an existing eos account to the members db and transfer an amount of tokens to the given account. It must be called from the contract owner account.

Parameters:

* **newmember** - a pre-existing eos account to be added to this contract as a member.
* **quantity** - an asset to transfer from the contract account to the newmember account.
* **memo** - a string to pass to the underlying transfer method on the `eosio.token` contract.

***Note:*** *The `agreedterms` would be left un-set after this action since the user has not yet agreed to the terms. This would be completed by the individual account holder with their required permission.*

## memberadda
This is a pluralised version of the `memberadd` action to facilitate batch importing members in one action.

Parameters:

* **newmembers** - a vector of objects representing pre-existing eos accounts and an asset quantity to transfer.
* **memo** - a string to pass in for the transfer action as in the single version of this action. The same memo would be used for all transfers to save space of the message.

## memberreg

This is called to indicate that the account has agreed to the terms of the DAC.  It will update an internal database of member accounts.  This action must supply the hash of the agreement, most recently agreed to, and can be called multiple times to update the hash.

Parameters:

* **sender** - (account_name) - The account registering
* **agreedterms** (string) - The hash of the agreed constitution

Check that the account has permissions of account
Update the members database to include the account name and the new hash

## memberunreg

Unregister the account, this signifies that they no longer agree to any terms and we should update the database to remove the account.

Parameters:

* **sender** (account_name) - The account unregistering

Check that the account has permissions of account
Update the members database to remove the account name


## burn

Will burn tokens by removing them from the account and reducing the total supply variable. This could be used by worker proposals to burn some of the eosDAC tokens.

Parameters:

* **quantity** - an asset to burn

***Note:*** *This action ensures that the burn amount will only burn available tokens that have not been allocated to other users (part of the circulating supply) or is greater than the available supply.*


## clear (for debugging)

This action is used for debugging only and should **not** be deployed to the production chain.
It is required for the unit tests to first clear the created token and member tables. Ideally this would be hidden behind a compiler flag but this does not seem possible with the current `eosiocpp` implementation.