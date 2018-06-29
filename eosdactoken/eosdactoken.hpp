/**
 *  @file
 *  @copyright defined in eos/LICENSE.txt
 */
#pragma once

#include <eosiolib/asset.hpp>
#include <eosiolib/eosio.hpp>
#include <eosiolib/multi_index.hpp>

#include <string>

namespace eosiosystem {
   class system_contract;
}

using namespace eosio;
using namespace std;

struct member {
    name sender;
    /// Hash of agreed terms
    string agreedterms;

    name primary_key() const { return sender; }

    EOSLIB_SERIALIZE(member, (sender)(agreedterms))
};

typedef multi_index<N(members), member> regmembers;

namespace eosdac {

   using std::string;

   class eosdactoken : public contract {
      public:
         eosdactoken(account_name self) : contract(self), registeredgmembers(_self, _self) {}

         void create( account_name issuer,
                      asset        maximum_supply,
                      bool         transfer_locked);

         void issue( account_name to, asset quantity, string memo );

         void unlock( asset unlock );

         void burn(account_name from, asset quantity );

         void transfer( account_name from,
                        account_name to,
                        asset        quantity,
                        string       memo );

         void memberreg(name sender, string agreedterms);

         void memberunreg(name sender);

      private:

         friend eosiosystem::system_contract;

         inline asset get_supply( symbol_name sym )const;

         inline asset get_balance( account_name owner, symbol_name sym )const;

         regmembers registeredgmembers;


      public:
         struct account {
            asset    balance;

            uint64_t primary_key()const { return balance.symbol.name(); }
         };

         struct currency_stats {
            asset          supply;
            asset          max_supply;
            account_name   issuer;
            bool           transfer_locked = false;

            uint64_t primary_key()const { return supply.symbol.name(); }
         };

         typedef eosio::multi_index<N(accounts), account> accounts;
         typedef eosio::multi_index<N(stat), currency_stats> stats;

         void sub_balance( account_name owner, asset value, const currency_stats& st );
         void add_balance( account_name owner, asset value, const currency_stats& st,
                           account_name ram_payer );

   };

   asset eosdactoken::get_supply( symbol_name sym )const
   {
      stats statstable( _self, sym );
      const auto& st = statstable.get( sym );
      return st.supply;
   }

   asset eosdactoken::get_balance( account_name owner, symbol_name sym )const
   {
      accounts accountstable( _self, owner );
      const auto& ac = accountstable.get( sym );
      return ac.balance;
   }

} /// namespace eosdac
