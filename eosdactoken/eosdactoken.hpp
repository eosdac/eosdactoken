#include <eosiolib/eosio.hpp>
#include <eosiolib/multi_index.hpp>
#include "eosio.token.hpp"

using namespace eosio;
using namespace std;

template <typename T>
void cleanTable(uint64_t code, uint64_t account){
  T db(code, account);
  while(db.begin() != db.end()){
      auto itr = --db.end();
      db.erase(itr);
      }
}

// @abi table members
struct member {
    name sender;
    /// Hash of agreed terms
    string agreedterms;

    name primary_key() const { return sender; }

    EOSLIB_SERIALIZE(member, (sender)(agreedterms))
};

struct memberraw {
  name sender;
  asset quantity;

  EOSLIB_SERIALIZE(memberraw, (sender)(quantity))
};

typedef multi_index<N(members), member> regmembers;
