#!/bin/bash

source eosio_helpers_common

token="EDB"

color_printf "Create a new currency"
exe cleos push action ${CONTRACT_NAME} create '{ "issuer": "'${ACCOUNT_NAME}'", "maximum_supply": "10000.0000 '${token}'", "can_freeze": 0, "can_recall": 0, "can_whitelist": 0}' -p ${ACCOUNT_NAME}

color_printf "Issue some to new currency"
exef cleos push action ${CONTRACT_NAME} issue '{ "to": "'${ACCOUNT_NAME}'", "quantity": "1000.0000 '${token}'", "memo": "Initial amount of tokens for you."}' -p ${ACCOUNT_NAME}

color_printf "Issue too much new currency - should fail"
exe cleos push action ${CONTRACT_NAME} issue '{ "to": "'${ACCOUNT_NAME}'", "quantity": "11000.0000 '${token}'", "memo": "Initial amount of tokens for you."}' -p ${ACCOUNT_NAME}

color_printf "Read back the stats"
exe cleos get currency stats ${CONTRACT_NAME} ${token}

color_printf "Transfer some tokens - should succeed"
exef cleos push action ${CONTRACT_NAME} transfer '{ "from": "'${ACCOUNT_NAME}'", "to": "eosio", "quantity": "500.0000 '${token}'", "memo": "my first transfer"}' --permission ${ACCOUNT_NAME}@active

color_printf "Read back the result balance - should increase"
exef cleos get currency balance ${CONTRACT_NAME} ${ACCOUNT_NAME}

color_printf "Burn too many tokens - should fail"
exe cleos push action ${CONTRACT_NAME} burn '{ "quantity": "9500.0000 '${token}'"}' -p ${ACCOUNT_NAME}

color_printf "Burn tokens with wrong auth - should fail"
exe cleos push action ${CONTRACT_NAME} burn '{ "quantity": "500.0000 '${token}'"}' -p eosio

color_printf "Burn a legal amount of tokens - should succeed"
exef cleos push action ${CONTRACT_NAME} burn '{ "quantity": "500.0000 '${token}'"}' -p ${ACCOUNT_NAME}

color_printf "Read back the stats should be less now"
exef cleos get currency stats ${CONTRACT_NAME} ${token}

color_printf "Read back the result balance - should increase"
exef cleos get currency balance ${CONTRACT_NAME} ${ACCOUNT_NAME}

color_printf "Member reg - succeed"
exe cleos push action ${CONTRACT_NAME} memberreg '{ "sender": "eosio", "agreedterms": "initaltermsagre'${token}'yuser"}' -p eosio

color_printf "Read back the result for regmembers - should have 1 with matching terms"
exef cleos get table ${CONTRACT_NAME} ${CONTRACT_NAME} members

color_printf "Update existing member reg without auth - should fail"
exe cleos push action ${CONTRACT_NAME} memberreg '{ "sender": "eosio", "agreedterms": "subsequenttermsagre'${token}'yuser"}'

color_printf "Update existing member reg - should succeed with new terms"
exe cleos push action ${CONTRACT_NAME} memberreg '{ "sender": "eosio", "agreedterms": "subsequenttermsagre'${token}'yuser"}' -p eosio@active

color_printf "Read back the result for regmembers - should have 1 with new terms"
exef cleos get table ${CONTRACT_NAME} ${CONTRACT_NAME} members

color_printf "Unregister existing member reg without correct auth should fail"
exe cleos push action ${CONTRACT_NAME} memberunreg '{ "sender": "eosio"}' -p currency@active

color_printf "Unregister existing member reg with correct auth should succeed with last agreed terms"
exe cleos push action ${CONTRACT_NAME} memberunreg '{ "sender": "eosio"}' -p eosio@active

color_printf "Read back the result for regmembers should be empty"
exef cleos get table ${CONTRACT_NAME} ${CONTRACT_NAME} members

exe cleos push action ${CONTRACT_NAME} clear '"message"' -p eosio

