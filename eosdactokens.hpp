/**
 *  @file
 *  @copyright defined in eos/LICENSE.txt
 */
#pragma once

#include <eosiolib/asset.hpp>
#include <eosiolib/eosio.hpp>
#include <eosiolib/multi_index.hpp>
#include <eosiolib/singleton.hpp>

#include <string>

namespace eosiosystem {
    class system_contract;
}

using namespace eosio;
using namespace std;

namespace eosdac {

    using std::string;

    class [[eosio::contract("eosdactokens")]] eosdactokens : public contract {
    public:

        using contract::contract;
        eosdactokens( name s, name code, datastream<const char*> ds );

        [[eosio::action]]
        void create(name issuer,
                    asset maximum_supply,
                    bool transfer_locked);

        [[eosio::action]]
        void issue(name to, asset quantity, string memo);

        [[eosio::action]]
        void unlock(asset unlock);

        [[eosio::action]]
        void burn(name from, asset quantity);

        [[eosio::action]]
        void transfer(name from,
                      name to,
                      asset quantity,
                      string memo);

        [[eosio::action]]
        void newmemterms(string terms, string hash);

        [[eosio::action]]
        void memberreg(name sender, string agreedterms);

        [[eosio::action]]
        void memberunreg(name sender);

        [[eosio::action]]
        void updateconfig(name notifycontr);

        [[eosio::action]]
        void updateterms(uint64_t termsid, string terms);

    private:

        struct contr_config {

            //The additional account to notify of any transfers. Currently used to maintain "live" vote counts.
            name notifycontr = "daccustodian"_n;

            EOSLIB_SERIALIZE(contr_config,
            (notifycontr)

            )
        };

        typedef singleton<"config"_n, contr_config> configscontainer;


        struct [[eosio::table, eosio::contract("eosdactokens")]] member {
            name sender;
            // agreed terms version
            uint64_t agreedtermsversion;

            uint64_t primary_key() const { return sender.value; }

            EOSLIB_SERIALIZE(member, (sender)(agreedtermsversion)
            )
        };

        struct [[eosio::table, eosio::contract("eosdactokens")]] termsinfo {
            string terms;
            string hash;
            uint64_t version;

            termsinfo()
                    : terms(""), hash(""), version(0) {}

            termsinfo(string _terms, string _hash, uint64_t _version)
                    : terms(_terms), hash(_hash), version(_version) {}

            uint64_t primary_key() const { return version; }
            uint64_t by_latest_version() const { return UINT64_MAX - version; }

          EOSLIB_SERIALIZE(termsinfo, (terms)(hash)(version))
        };

        typedef multi_index<"members"_n, member> regmembers;

        typedef multi_index<"memberterms"_n, termsinfo,
                indexed_by<"bylatestver"_n, const_mem_fun<termsinfo, uint64_t, &termsinfo::by_latest_version> >
        > memterms;

        friend eosiosystem::system_contract;

        inline asset get_supply(symbol_code sym) const;

        inline asset get_balance(name owner, symbol_code sym) const;

        contr_config configs();

        regmembers registeredgmembers;
        memterms memberterms;

        configscontainer config_singleton;


    public:

        struct account {
            asset balance;

            uint64_t primary_key() const { return balance.symbol.code().raw(); }
        };

        struct currency_stats {
            asset supply;
            asset max_supply;
            name issuer;
            bool transfer_locked = false;

            uint64_t primary_key() const { return supply.symbol.code().raw(); }
        };

        typedef eosio::multi_index<"accounts"_n, account> accounts;
        typedef eosio::multi_index<"stat"_n, currency_stats> stats;

        void sub_balance(name owner, asset value, const currency_stats &st);

        void add_balance(name owner, asset value, const currency_stats &st,
                         name ram_payer);

    };

    asset eosdactokens::get_supply(symbol_code sym) const {
        stats statstable(_self, sym.raw());
        const auto &st = statstable.get(sym.raw());
        return st.supply;
    }

    asset eosdactokens::get_balance(name owner, symbol_code sym) const {
        accounts accountstable(_self, owner.value);
        const auto &ac = accountstable.get(sym.raw());
        return ac.balance;
    }
}
