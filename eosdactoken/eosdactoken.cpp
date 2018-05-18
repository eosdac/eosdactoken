#include <eosiolib/print.hpp>
#include "eosdactoken.hpp"

using namespace std;
using eosio::token;

class eosdactoken: public token {

public:
    eosdactoken(account_name self) : token(self), registeredgmembers(_self, _self) {}

    void memberadd(name newmember, asset quantity, string memo) {
        require_auth(_self);
        print("adding new account");

        auto existingMember = registeredgmembers.find(newmember);
        if(existingMember == registeredgmembers.end()) {
            registeredgmembers.emplace(_self, [&](member& mem) {
                mem.sender = newmember;
            });
        }

       SEND_INLINE_ACTION( *this, transfer, {_self,N(active)}, {_self, newmember, quantity, memo} );
    }

    void memberadda(vector<memberraw> newmembers, string memo) {
        require_auth(_self);

        print("adding vector of new accounts");

          for(vector<memberraw>::iterator it = newmembers.begin(); it != newmembers.end(); it++) {
            SEND_INLINE_ACTION( *this, memberadd, {_self,N(active)}, {it->sender, it->quantity, memo} );
        }
    }

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
            });
        }
    }

    void memberunreg(name sender) {
        require_auth(sender);

        auto regMember = registeredgmembers.find(sender);
        eosio_assert(regMember != registeredgmembers.end(), "Member is not registered");
        registeredgmembers.erase(regMember);
    }

    void clear(asset sym, account_name owner) {
        cleanTable<regmembers>(_self, _self);
        token::clear(sym, owner);

        print("clearing.....");
    }

private:
    regmembers registeredgmembers;
};

EOSIO_ABI(eosdactoken, (memberreg)(memberunreg)(clear)(create)(issue)(transfer)(burn)(memberadd)(memberadda))
