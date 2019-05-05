<h1 class="contract">
   create
</h1>

**PARAMETERS:** 
* __issuer__ is a type of eosio account_name
* __maximum_supply__ is a type of asset
* __transferred_locked__ is either 1 (true) or 0 (false)

**INTENT:** The intent of {{ create }} is to create a new token with a {{ maximum supply }} as indicated. The asset is created in the format of {{ number of tokens to 4 decimal places <space>  token symbol }} for example 1000.0000 DAC will create a DAC token with a maximum number of units of 1000.0000. If {{ transfer_locked }} is set to true then only the issuer may use the transfer action. 

**TERM:** The act of creation of this asset will expires at the conclusion of code execution. The asset will then persist on the deployed contract as long as it is active.

<h1 class="contract">
   issue
</h1>

**PARAMETERS:** 
* __to__ is a type of eosio accountname to issue tokens to
* __quantity__ is a type of eosio asset
* __memo__ is a string with a maximum of 256 characters
       
**INTENT:** The intent of {{ issue }} is to issue tokens {{ quantity }} and send them to the account specified {{ to }} using the transfer action. This requires a privileged account. A note {{ memo }} can be sent to the receiver.

**TERM:** The action lasts for the duration of the processing of the contract.

<h1 class="contract">
   unlock
</h1>


**PARAMETERS:** 
* __unlock__ is a type of asset

**INTENT:** The intent of {{ unlock }} is to unlock a token to allow transfers from accounts other than the token creator. The parameter passed in must be a standard asset in the form of "1000.0000 ABC". Although the amount component eg. 1000.000 is ignored for the logic it is required for the format of an asset parameter. This can only be done once to unlock a token and cannot be reversed to lock a token again.

**TERM:** The act of unlocking transfer on this asset will expires at the conclusion of code execution. Transfer functionality for the asset will then persist on the deployed contract as long as it is active.

<h1 class="contract">
   burn
</h1>

**PARAMETERS:** 
* __from__ is a type of eosio account_name for the owner of the tokens to burn.
* __quantity__ is a type of eosio asset

**INTENT:** The intent of {{ burn }} is to allow a user to burn {{ quantity }} tokens that belong to them. 

**TERM:** The burn action lasts for the duration of the processing of the contract. The reduction in token supply persists on the deployed contract as long as it is active.

<h1 class="contract">
   transfer
</h1>

**PARAMETERS:** 
* __from__ is a type of eosio account_name
* __to__ is a type of eosio account_name
* __quantity__ is a type of eosio asset
* __memo__ is a string with a maximum of 256 characters

**INTENT:** The intent of {{ transfer }} is to allow an account {{ from }} to send {{ quantity }} tokens to another account {{ to }}.  A note {{ memo }} can be sent to the receiver.

**TERM:** The transfer action represents a change in the asset balances of the accounts involved in the transaction."

<h1 class="contract">
   memberreg
</h1>

**PARAMETERS:** 
* __sender__ eos account name for a registering member
* __agreedterms__ is a hash reference to a document contained in a string with a maximum of 256 characters

**INTENT:** The intent of memberreg is to indicate that the account has agreed to the terms of the DAC. It will update an internal database of member accounts. This action must supply the hash of the agreement in {{ agreedterms }}, it will hold the most recently agreed to, and can be called multiple times to update the hash.

**TERM:** This action lasts for the duration of the processing of the contract. The member registration will persist on the deployed contract as long as it is active or superseded by an updated memberreg or memberunreg action.

<h1 class="contract">
   memberrege
</h1>

**PARAMETERS:** 
* __sender__ eos account name for a registering member
* __agreedterms__ hash reference to a document contained in a string with a maximum of 256 characters
* __managing_account__ eos account name to scope this action to a specific dac.

**INTENT:** The intent of memberreg is to indicate that the account has agreed to the terms of the DAC. It will update an internal database of member accounts. This action must supply the hash of the agreement in {{ agreedterms }}, it will hold the most recently agreed to, and can be called multiple times to update the hash.

**TERM:** This action lasts for the duration of the processing of the contract. The member registration will persist on the deployed contract as long as it is active or superseded by an updated memberreg or memberunreg action.


<h1 class="contract">
   memberunreg
</h1>

**PARAMETERS:** 
* __sender__ eos account name for a unregistering member

**INTENT:** The intent of memberunreg is to allow an account {{ sender }} to unregister its membership.

**TERM:** This action lasts for the duration of the processing of the contract. The action will persist on the deployed contract as long as it is active or superseded by an updated memberreg action.

<h1 class="contract">
   memberunrege
</h1>

**PARAMETERS:** 
* __sender__ eos account name for a unregistering member
* __managing_account__ eos account name to scope this action to a specific dac.

**INTENT:** The intent of memberunreg is to allow an account {{ sender }} to unregister its membership.

**TERM:** This action lasts for the duration of the processing of the contract. The action will persist on the deployed contract as long as it is active or superseded by an updated memberreg action.

<h1 class="contract">
   updateterms
</h1>

**PARAMETERS:** 
* __termsid__ is a number id of the terms reference stored in the contract.
* __terms__ is checksum hash of the updated terms.

**INTENT:** The intent of {{ updateterms }} is to change the URL link specifying where the terms of a pre-existing record of member terms are located, associated with the given version {{ termsid }}.

**TERM:** The update terms action lasts until it is superseded by a subsequent action.

<h1 class="contract">
   updatetermse
</h1>

**PARAMETERS:** 
* __termsid__ is a number id of the terms reference stored in the contract.
* __terms__ is checksum hash of the updated terms.
* __managing_account__ eos account name to scope this action to a specific dac.

**INTENT:** The intent of {{ updatetermse }} is to change the URL link specifying where the terms of a pre-existing record of member terms are located, associated with the given version {{ termsid }}.

**TERM:** The update terms action lasts until it is superseded by a subsequent action.

<h1 class="contract">
   updateconfig
</h1>

**PARAMETERS:** 
* __notifycontr__ is a contract to also be notified of all transactions in this token contract.

**INTENT:** Notify a listening contract so that it can update it's internal state based on transactions in here.

**TERM:** The updateconfig action lasts for the duration of the processing of the contract.

<h1 class="contract">
   close
</h1>

**PARAMETERS:** 
* __owner__ is the owner of a balance entry for the token.
* __symbol__ is the symbol for the currency entry to close

**INTENT:** Close a balance entry for a token. This allows for a 0 balance to be kept open while still holding a valid entry in the token table.
Term: The updateconfig action lasts for the duration of the processing of the contract.


<h1 class="contract">
   newmemterms
</h1>

**PARAMETERS:** 
* __terms__ content for new member terms so that they can accessed on the front end clients.
* __hash__ a checksum hash to verify the contents that would be be agreed to on the client has not been changed. 

**INTENT:** Add an updated member terms entry after content has been changed in the member agreement.

**TERM:** The newmemterms action lasts for the duration of the processing of the contract.

<h1 class="contract">
   newmemtermse
</h1>

**PARAMETERS:** 
* __terms__ content for new member terms so that they can accessed on the front end clients.
* __hash__ a checksum hash to verify the contents that would be be agreed to on the client has not been changed. 
* __managing_account__ eos account name to scope this action to a specific dac.

**INTENT:** Add an updated member terms entry after content has been changed in the member agreement.

**TERM:** The newmemterms action lasts for the duration of the processing of the contract.