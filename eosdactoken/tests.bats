#!/bin/bash
#!/usr/bin/env bats

# For tests to run it is assumed the there is an active, unlocked wallet with a eosdactoken and eosio account.

@test "Clear all tables first (only for debugging and testing)" {
run cleos push action eosdactoken clear '{ "sym": "1.0 ABC", "owner": "eosdactoken"}' -p eosio
   echo $output >&2
  [ $status -eq 0 ]
  [[ "$output" =~ .*eosdactoken::clear.* ]]
}

@test "Create a new currency without account auth should fail" {
run cleos push action eosdactoken create '{ "issuer": "eosdactoken", "maximum_supply": "10000.0000 ABC", "can_freeze": 0, "can_recall": 0, "can_whitelist": 0}'
   echo $output >&2
  [ $status -eq 1 ]
  [[ "$output" =~ .*'transaction must have at least one authorization'.* ]]
}

@test "Create a new currency with mismatching auth should fail" {
run cleos push action eosdactoken create '{ "issuer": "eosdactoken", "maximum_supply": "10000.0000 ABC", "can_freeze": 0, "can_recall": 0, "can_whitelist": 0}' -p eosio
   echo $output >&2
  [ $status -eq 1 ]
  [[ "$output" =~ .*'missing authority of eosdactoken'.* ]]
}

@test "Create a new currency with matching issuer and account auth should succeed." {
run cleos push action eosdactoken create '{ "issuer": "eosdactoken", "maximum_supply": "10000.0000 ABC", "can_freeze": 0, "can_recall": 0, "can_whitelist": 0}' -p eosdactoken
   echo $output >&2
  [ $status -eq 0 ]
  [[ "$output" =~ .*eosdactoken::create.* ]]
}

@test "Issue new currency without valid auth should fail" {
run cleos push action eosdactoken issue '{ "to": "eosdactoken", "quantity": "1000.0000 ABC", "memo": "Initial amount of tokens for you."}'
   echo $output >&2
  [ "$status" -eq 1 ]
  [[ "$output" =~ .*'transaction must have at least one authorization'.* ]]
}

@test "Issue new currency with mismatching auth should fail" {
run cleos push action eosdactoken issue '{ "to": "eosdactoken", "quantity": "1000.0000 ABC", "memo": "Initial amount of tokens for you."}' -p eosio
   echo $output >&2
  [ "$status" -eq 1 ]
  [[ "$output" =~ .*'missing authority of eosdactoken'.* ]]
}

@test "Issue new currency with valid auth should succeed" {
run cleos push action eosdactoken issue '{ "to": "eosdactoken", "quantity": "1000.0000 ABC", "memo": "Initial amount of tokens for you."}' -p eosdactoken
   echo $output >&2
  [ "$status" -eq 0 ]
  [[ "$output" =~ .*eosdactoken::issue.* ]]
}

@test "Issue currency greater than max should fail" {
run cleos push action eosdactoken issue '{ "to": "eosdactoken", "quantity": "11000.0000 ABC", "memo": "Initial amount of tokens for you."}' -p eosdactoken
   echo $output >&2
   [ "$status" -eq 1 ]
   [[ "$output" =~ .*'quantity exceeds available supply'.* ]]
}

@test "Read back the stats after issuing currency should display max supply, supply and issuer" {
run cleos get currency stats eosdactoken ABC
   echo $output >&2
   [ "$status" -eq 0 ]
   [[ "$output" =~ .*'"max_supply": "10000.0000 ABC"'.* ]]
   [[ "$output" =~ .*'"issuer": "eosdactoken"'.* ]]
   [[ "$output" =~ .*'"supply": "1000.0000 ABC"'.* ]]
}

@test "Transfer some tokens without auth should fail" {
run cleos push action eosdactoken transfer '{ "from": "eosdactoken", "to": "eosio", "quantity": "500.0000 ABC", "memo": "my first transfer"}'
   echo $output >&2
   [ "$status" -eq 1 ]
   [[ "$output" =~ .*'transaction must have at least one authorization'.* ]]
}

@test "Transfer some tokens with mismatching auth should fail" {
run cleos push action eosdactoken transfer '{ "from": "eosdactoken", "to": "eosio", "quantity": "500.0000 ABC", "memo": "my first transfer"}' -p eosio
   echo $output >&2
   [ "$status" -eq 1 ]
   [[ "$output" =~ .*'missing authority of eosdactoken'.* ]]
}

@test "Transfer some tokens with auth should succeed" {
run cleos push action eosdactoken transfer '{ "from": "eosdactoken", "to": "eosio", "quantity": "500.0000 ABC", "memo": "my first transfer"}' --permission eosdactoken@active
   echo $output >&2
   [ "$status" -eq 0 ]
}

@test "Read back the result balance" {
run cleos get currency balance eosdactoken eosdactoken
   echo $output >&2
   [ "$status" -eq 0 ]
   [[ "$output" =~ .*"500.0000 ABC".* ]]
}

@test "Transfer tokens amount grgater than balance should fail" {
run cleos push action eosdactoken transfer '{ "from": "eosio", "to": "eosdactoken", "quantity": "50000.0000 ABC", "memo": "my first transfer"}' -p eosio
   echo $output >&2
   [ "$status" -eq 1 ]
   [[ "$output" =~ .*'overdrawn balance'.* ]]
}

@test "Burn more than available supply should fail" {
run cleos push action eosdactoken burn '{ "quantity": "9500.0000 ABC"}' -p eosdactoken
   echo $output >&2
   [ "$status" -eq 1 ]
   [[ "$output" =~ .*"burn quantity exceeds available supply".* ]]
}

@test "Burn tokens without auth should fail" {
run cleos push action eosdactoken burn '{ "quantity": "500.0000 ABC"}'
   echo $output >&2
   [ "$status" -eq 1 ]
   [[ "$output" =~ .*'transaction must have at least one authorization'.* ]]
}

@test "Burn tokens with wrong auth should fail" {
run cleos push action eosdactoken burn '{ "quantity": "500.0000 ABC"}' -p eosio
   echo $output >&2
   [ "$status" -eq 1 ]
   [[ "$output" =~ .*"missing authority of eosdactoken".* ]]
}

@test "Burn a legal amount of tokens should succeed" {
run cleos push action eosdactoken burn '{ "quantity": "500.0000 ABC"}' -p eosdactoken
   echo $output >&2
   [ "$status" -eq 0 ]
   [[ "$output" =~ .*"eosdactoken::burn".* ]]
}

@test "Stats and max supply should be less now" {
run cleos get currency stats eosdactoken ABC
   echo $output >&2
   [ "$status" -eq 0 ]
   [[ "$output" =~ .*'"max_supply": "9500.0000 ABC"'.* ]]
   [[ "$output" =~ .*'"supply": "1000.0000 ABC"'.* ]]
   [[ "$output" =~ .*'"issuer": "eosdactoken"'.* ]]
}

@test "Member reg without auth should fail" {
run cleos push action eosdactoken memberreg '{ "sender": "eosio", "agreedterms": "initaltermsagreedbyuser"}'
   echo $output >&2
   [ "$status" -eq 1 ]
   [[ "$output" =~ .*'transaction must have at least one authorization'.* ]]
}

@test "Member reg with mismatching auth should fail" {
run cleos push action eosdactoken memberreg '{ "sender": "eosio", "agreedterms": "initaltermsagreedbyuser"}' -p eosdactoken
   echo $output >&2
   [ "$status" -eq 1 ]
   [[ "$output" =~ .*"missing authority of eosio".* ]]
}

@test "Member reg with valid auth for should succeed" {
run cleos push action eosdactoken memberreg '{ "sender": "eosio", "agreedterms": "initaltermsagreedbyuser"}' -p eosio
   echo $output >&2
   [ "$status" -eq 0 ]
   [[ "$output" =~ .*"eosdactoken::memberreg".* ]]
}

@test "Read back the result for regmembers - hasagreed should be 1" {
run cleos get table eosdactoken eosdactoken members
   echo $output >&2
   [ "$status" -eq 0 ]
   [[ "$output" =~ .*'"agreedterms": "initaltermsagreedbyuser"'.* ]]
   [[ "$output" =~ .*'"sender": "eosio"'.* ]]
   [[ "$output" =~ .*'"hasagreed": 1'.* ]]
}

@test "Update existing member reg without auth should fail" {
run cleos push action eosdactoken memberreg '{ "sender": "eosio", "agreedterms": "subsequenttermsagreedbyuser"}'
   echo $output >&2
   [ "$status" -eq 1 ]
   [[ "$output" =~ .*"transaction must have at least one authorization".* ]]
}

@test "Update existing member reg with mistmatching auth should fail" {
run cleos push action eosdactoken memberreg '{ "sender": "eosio", "agreedterms": "subsequenttermsagreedbyuser"}' -p eosdactoken
   echo $output >&2
   [ "$status" -eq 1 ]
   [[ "$output" =~ .*"missing authority of eosio".* ]]
}

@test "Update existing member reg with auth" {
run cleos push action eosdactoken memberreg '{ "sender": "eosio", "agreedterms": "subsequenttermsagreedbyuser"}' -p eosio@active
   echo $output >&2
   [ "$status" -eq 0 ]
   [[ "$output" =~ .*"eosdactoken::memberreg".* ]]
}

@test "Read back the result for regmembers - hasagreed should be 1" {
run cleos get table eosdactoken eosdactoken members
   echo $output >&2
   [ "$status" -eq 0 ]
   [[ "$output" =~ .*"subsequenttermsagreedbyuser".* ]]
   [[ "$output" =~ .*'"sender": "eosio"'.* ]]
   [[ "$output" =~ .*'"hasagreed": 1'.* ]]
}

@test "Unregister existing member reg without correct auth" {
run cleos push action eosdactoken memberunreg '{ "sender": "eosio"}'
   echo $output >&2
   [ "$status" -eq 1 ]
   [[ "$output" =~ .*"transaction must have at least one authorization".* ]]
}

@test "Unregister existing member reg with mismatching auth" {
run cleos push action eosdactoken memberunreg '{ "sender": "eosio"}' -p currency@active
   echo $output >&2
   [ "$status" -eq 1 ]
   [[ "$output" =~ .*"but does not have signatures for it".* ]]
}

@test "Unregister existing member reg with correct auth" {
run cleos push action eosdactoken memberunreg '{ "sender": "eosio"}' -p eosio@active
   echo $output >&2
   [ "$status" -eq 0 ]
   [[ "$output" =~ .*'eosdactoken::memberunreg'.* ]]
}

@test "Read back the result for regmembers has agreed should be 0" {
run cleos get table eosdactoken eosdactoken members
   echo $output >&2
   [ "$status" -eq 0 ]
   [[ "$output" =~ .*"subsequenttermsagreedbyuser".* ]]
   [[ "$output" =~ .*'"sender": "eosio"'.* ]]
   [[ "$output" =~ .*'"hasagreed": 0'.* ]]
}
