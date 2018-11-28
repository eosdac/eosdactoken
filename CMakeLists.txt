
cmake_minimum_required(VERSION 3.5)
project(eosdactokens VERSION 1.0.0)

find_package(eosio.cdt)

add_contract( eosdactokens eosdactokens eosdactokens.cpp )