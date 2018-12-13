#!/usr/bin/env bash

eosio-cpp -o output/jungle/eosdactokens/eosdactokens.wasm eosdactokens.cpp
eosio-abigen eosdactokens.hpp -contract eosdactokens -output output/jungle/eosdactokens/eosdactokens.abi