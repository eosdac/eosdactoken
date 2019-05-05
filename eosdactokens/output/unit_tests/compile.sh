#!/usr/bin/env bash

eosio-cpp -o output/unit_tests/eosdactokens/eosdactokens.wasm eosdactokens.cpp
eosio-abigen eosdactokens.hpp -contract eosdactokens -output output/unit_tests/eosdactokens/eosdactokens.abi