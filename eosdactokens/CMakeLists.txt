
cmake_minimum_required(VERSION 3.5)
project(eosdactokens VERSION 1.0.0)

find_package(eosio.cdt)

#include_directories(${eosio.cdt} )



add_contract( eosdactokens eosdactokens eosdactokens.cpp eosdactokens.hpp )

target_compile_options( eosdactokens.wasm PUBLIC -R${CMAKE_CURRENT_SOURCE_DIR} )