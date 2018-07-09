## CONTRACT FOR EOSDAC TOKEN/MEMBER CONTRACT 

**OVERALL FUNCTION** : This contract creates the currency and also give a means to say whether an eosDAC account holder is a member. A member is classified as a token holder who has registered and agreed to the membership agreement. This contract also covers the standard token transfer and account balance functions

## ACTION: create

**PARAMETERS:** __issuer__ is a type of eosio account_name , __maximum_supply__ is a type of asset, __transferred_locked__ is either 1 (true) or 0 (false)

**INTENT:** The intent of {{ create }} is to create a new token with a {{ maximum supply }} as indicated. The asset is created in the format of {{ number of tokens to 4 decimal places <space>  token symbol }} for example 1000.0000 DAC will create a DAC token with a maximum number of units of 1000.0000. If {{ transfer_locked }} is set to true then only the issuer may use the transfer action. 

**TERM:** The act of creation of this asset will expires at the conclusion of code execution. The asset will then persist on the deployed contract as long as it is active.

## ACTION: issue

**PARAMETERS:** __to__ is a type of eosio accountname , __quantity__ is a type of eosio asset, __memo__ is a string with a maximum of 256 charaters
       
**INTENT:** The intent of {{ issue }} is to issue tokens {{ quantity }} and send them to the account specified {{ to }} using the transfer action. This requires a privilaged account. A note {{ memo }} can be sent to the receiver.

**TERM:** The action lasts for the duration of the processing of the contract.

## ACTION: unlock

**PARAMETERS:** __unlock__ is a type of asset

**INTENT:** The intent of {{ unlock }} is to unlock a token to allow transfers from accounts other than the token creator. The parameter passed in must be a standard asset in the form of "1000.0000 ABC". Although the amount component eg. 1000.000 is ignored for the logic it is required for the format of an asset parameter. This can only be done once to unlock a token and cannot be reversed to lock a token again.

**TERM:** The act of unlocking transfer on this asset will expires at the conclusion of code execution. Transfer functionality for the asset will then persist on the deployed contract as long as it is active.

## ACTION: burn

**PARAMETERS:** __quantity__ is a type of eosio asset

**INTENT:** The intent of {{ burn }} is to allow a user to burn {{ quantity }} tokens that belong to them. 

**TERM:** The action lasts for the duration of the processing of the contract. The reduction in token supply persists on the deployed contract as long as it is active.

## ACTION: transfer

**PARAMETERS:** __from__ is a type of eosio account_name, __to__ is a type of eosio account_name, __quantity__ is a type of eosio asset, __memo__ is a string with a maximum of 256 characters

**INTENT:** The intent of {{ transfer }} is to allow an account {{ from }} to send {{ quantity }} tokens to another account {{ to }}.  A note {{ memo }} can be sent to the receiver.

**TERM:** The transfer action lasts for the duration of the processing of the contract.

## ACTION: account

**PARAMETERS:** __balance__ is a type of eosio asset

**INTENT:** The intent of {{ account }} is to return the current balance of specified tokens for an account.

**TERM:** This action lasts for the duration of the processing of the contract.

## ACTION: memberreg

**PARAMETERS:** __sender__ is a type of eosio account_name, __agreedterms__ is a hash reference to a document contained in a string with a maximum of 256 charaters

**INTENT:** The intent of memberreg is to indicate that the account has agreed to the terms of the DAC. It will update an internal database of member accounts. This action must supply the hash of the agreement in {{ agreedterms }}, it will hold the most recently agreed to, and can be called multiple times to update the hash.

**TERM:** This action lasts for the duration of the processing of the contract. The member registration will persist on the deployed contract as long as it is active or superceeded by an updated memberreg or memberunreg action.

## ACTION: memberunreg

**PARAMETERS:** __sender__ is a type of eosio account_name

**INTENT:** The intent of memberunreg is to allow an account {{ sender }} to unregister it's membership. 

**TERM:** This action lasts for the duration of the processing of the contract. The action will persist on the deployed contract as long as it is active or superceeded by an updated memberreg action.

## ACTION: currency_stats

**PARAMETERS:** returns __supply__ is a type of eosio asset, __max_supply__ is a type of eosio asset, __issuer__ is a type of eosio account_name, __transfer_locked__ is either True or False

**INTENT:** The intent of {{ currency_stats }} is to return information about a token as per the create, issue and burn action.

**TERM:** This action lasts for the duration of the processing of the contract.

## ACTION: memberadd

**PARAMETERS:** __new_member__ is a type of eosio account_name, __quantity__ is a type of eosio asset, __memo__ is a string with a maximum of 256 characters

**INTENT:** The intent of memberadd is to add an existing account {{ new_member }} to the members db and transfer {{ quantity }} tokens to the given account. It must be called from the contract owner account. A note {{ memo }} can be sent to the receiver.

**TERM:** This action lasts for the duration of the processing of the contract. The member registration will persist on the deployed contract as long as it is active or superceeded by an updated memberreg or memberunreg action.

## ACTION: memberraw

**PARAMETERS:** __sender__ is a type of eosio account_name, __quantity__ is a type of eosio asset

**INTENT:** The intent of {{ memberraw }} is to create an array of new members for use by the memberadda action

**TERM:** This action lasts for the duration of the processing of the contract.

## ACTION: memberadda

**PARAMETERS:** __newmembers__ is a group of memberraw, __memo__ is a string with a maximum of 256 characters

**INTENT:** The intent of memberadda is allow a group of accounts newmembers to be added as members. A memo can be sent to the receivers.

**TERM:** This action lasts for the duration of the processing of the contract. The member registration will persist on the deployed contract as long as it is active or superceeded by an updated memberreg or memberunreg action.

## ENTIRE AGREEMENT. 

This contract contains the entire agreement of the parties, for all described actions, and there are no other promises or conditions in any other agreement whether oral or written concerning the subject matter of this Contract. This contract supersedes any prior written or oral agreements between the parties. 

## BINDING CONSTITUTION: 

All the the action descibed in this contract are subject to the EOSDAC consitution as held at http://eosdac.io . This includes, but is not limited to membership terms and condiutions, dispute resolution and severability.  
