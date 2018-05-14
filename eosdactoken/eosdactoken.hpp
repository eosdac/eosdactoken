#include <eosiolib/eosio.hpp>
#include <eosiolib/multi_index.hpp>
#include "eosio.token.hpp"

using namespace eosio;
using namespace std;

// @abi table members
struct member {
    name sender;
    /// Hash of agreed terms
    string agreedterms;

    name primary_key() const { return sender; }

    EOSLIB_SERIALIZE(member, (sender)(agreedterms))
};

typedef multi_index<N(members), member> regmembers;
