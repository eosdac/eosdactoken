#include <eosiolib/print.hpp>
#include "eosdactoken.hpp"

using namespace std;
using eosio::token;

class eosdactoken: public token {

public:
    eosdactoken(account_name self) : token(self), registeredgmembers(_self, _self) {}

    void memberreg(name sender, string agreedterms) {
        require_auth(sender);

        auto existingMember = registeredgmembers.find(sender);
        if (existingMember != registeredgmembers.end()) {
            registeredgmembers.modify(existingMember, _self, [&](member& mem){
                mem.agreedterms = agreedterms;
            });
        } else {
            registeredgmembers.emplace(_self, [&](member& mem) {
                mem.sender = sender;
                mem.agreedterms = agreedterms;
                mem.hasagreed = true;
            });
        }
    }

    void memberunreg(name sender) {
        require_auth(sender);

        auto regMember = registeredgmembers.find(sender);
        eosio_assert(regMember != registeredgmembers.end(), "Member is not registered");
            registeredgmembers.modify(regMember, _self, [&](member& mem){
                mem.hasagreed = false;
            });
    }

    void clear(string message) {
        cleanTable<regmembers>();
        print("clearing.....", message.c_str());
    }

private:
    regmembers registeredgmembers;

    template <typename T>
    void cleanTable(){
        T db(_self, _self);
        while(db.begin() != db.end()){
            auto itr = --db.end();
            db.erase(itr);
        }
    }
};

EOSIO_ABI(eosdactoken, (memberreg)(memberunreg)(clear)(create)(issue)(transfer)(burn))
