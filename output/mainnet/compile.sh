#!/usr/bin/env bash

eosio-cpp -o output/mainnet/eosdactokens/eosdactokens.wasm eosdactokens.cpp
eosio-abigen eosdactokens.hpp -contract eosdactokens -output output/mainnet/eosdactokens/eosdactokens.abi