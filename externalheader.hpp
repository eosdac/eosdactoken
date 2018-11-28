
struct [[eosio::table("candidates")]] candidate {
    name candidate_name;
    asset requestedpay;
    asset locked_tokens;
    uint64_t total_votes;
    uint8_t is_active;
    uint32_t custodian_end_time_stamp;

    uint64_t primary_key() const { return candidate_name.value; }

    uint64_t by_number_votes() const { return static_cast<uint64_t>(total_votes); }

    uint64_t by_votes_rank() const { return static_cast<uint64_t>(UINT64_MAX - total_votes); }

    uint64_t by_requested_pay() const { return static_cast<uint64_t>(requestedpay.amount); }

    EOSLIB_SERIALIZE(candidate,
    (candidate_name)(requestedpay)(locked_tokens)(total_votes)(is_active)(custodian_end_time_stamp))
};

typedef multi_index<"candidates"_n, candidate,
        indexed_by<"bycandidate"_n, const_mem_fun<candidate, uint64_t, &candidate::primary_key> >,
indexed_by<"byvotes"_n, const_mem_fun<candidate, uint64_t, &candidate::by_number_votes> >,
indexed_by<"byvotesrank"_n, const_mem_fun<candidate, uint64_t, &candidate::by_votes_rank> >,
indexed_by<"byreqpay"_n, const_mem_fun<candidate, uint64_t, &candidate::by_requested_pay> >
> candidates_table;