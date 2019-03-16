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

    CONTRACT eosdactokens : public contract {
    public:

        using contract::contract;
        eosdactokens( name s, name code, datastream<const char*> ds );

        ACTION create(name issuer,
                    asset maximum_supply,
                    bool transfer_locked);

        ACTION issue(name to, asset quantity, string memo);

        ACTION unlock(asset unlock);

        ACTION burn(name from, asset quantity);

        ACTION transfer(name from,
                      name to,
                      asset quantity,
                      string memo);

        ACTION newmemterms(string terms, string hash);
        ACTION newmemtermse(string terms, string hash, name managing_account);

        ACTION memberreg(name sender, string agreedterms);
        ACTION memberrege(name sender, string agreedterms, name managing_account);

        ACTION memberunreg(name sender);
        ACTION memberunrege(name sender, name managing_account);

        ACTION updateconfig(name notifycontr);

        ACTION updateterms(uint64_t termsid, string terms);
        ACTION updatetermse(uint64_t termsid, string terms, name managing_account);

        ACTION close(name owner, const symbol& symbol);


    struct [[eosio::table("config")]] contr_config {

            //The additional account to notify of any transfers. Currently used to maintain "live" vote counts.
            name notifycontr = "daccustodian"_n;

            EOSLIB_SERIALIZE(contr_config,
            (notifycontr)

            )
        };

        typedef singleton<"config"_n, contr_config> configscontainer;


        TABLE member {
            name sender;
            // agreed terms version
            uint64_t agreedtermsversion;

            uint64_t primary_key() const { return sender.value; }

            EOSLIB_SERIALIZE(member, (sender)(agreedtermsversion)
            )
        };

        TABLE termsinfo {
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

        configscontainer config_singleton;


    public:

        TABLE account {
            asset balance;

            uint64_t primary_key() const { return balance.symbol.code().raw(); }
        };

        TABLE currency_stats {
            asset supply;
            asset max_supply;
            name issuer;
            bool transfer_locked = false;

            uint64_t primary_key() const { return supply.symbol.code().raw(); }
        };

        typedef eosio::multi_index<"accounts"_n, account> accounts;
        typedef eosio::multi_index<"stat"_n, currency_stats> stats;

        void sub_balance(name owner, asset value);

        void add_balance(name owner, asset value, name payer);

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
