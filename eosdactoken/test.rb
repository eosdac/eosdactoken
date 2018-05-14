require 'rspec_command'
require "json"

RSpec.configure do |config|
  config.include RSpecCommand
end

describe "Clear all tables first (only for debugging and testing)" do
  command  %(cleos push action eosdactoken clear '{ "sym": "1.0 ABC", "owner": "eosdactoken"}' -p eosio), allow_error: true
  its(:stdout) { is_expected.to include('eosdactoken::clear') }
end

describe "Create a new currency" do
  context "without account auth should fail" do
    command %(cleos push action eosdactoken create '{ "issuer": "eosdactoken", "maximum_supply": "10000.0000 ABC", "can_freeze": 0, "can_recall": 0, "can_whitelist": 0}'), allow_error: true
    its(:stderr) { is_expected.to include('transaction must have at least one authorization') }
  end

  context "with mismatching auth should fail" do
    command %(cleos push action eosdactoken create '{ "issuer": "eosdactoken", "maximum_supply": "10000.0000 ABC", "can_freeze": 0, "can_recall": 0, "can_whitelist": 0}' -p eosio), allow_error: true
    its(:stderr) { is_expected.to include('missing authority of eosdactoken') }
  end

  context "with matching issuer and account auth should succeed." do
    command %(cleos push action eosdactoken create '{ "issuer": "eosdactoken", "maximum_supply": "10000.0000 ABC", "can_freeze": 0, "can_recall": 0, "can_whitelist": 0}' -p eosdactoken), allow_error: true
    its(:stdout) { is_expected.to include('eosdactoken::create') }
  end
end

describe "Issue new currency" do
  context "without valid auth should fail" do
    command %(cleos push action eosdactoken issue '{ "to": "eosdactoken", "quantity": "1000.0000 ABC", "memo": "Initial amount of tokens for you."}'), allow_error: true
    its(:stderr) { is_expected.to include('transaction must have at least one authorization') }
  end

  context "without owner auth should fail" do
    command %(cleos push action eosdactoken issue '{ "to": "tester1", "quantity": "1000.0000 ABC", "memo": "Initial amount of tokens for you."} -p tester1'), allow_error: true
    its(:stderr) { is_expected.to include('transaction must have at least one authorization') }
  end

  context "with mismatching auth should fail" do
    command %(cleos push action eosdactoken issue '{ "to": "eosdactoken", "quantity": "1000.0000 ABC", "memo": "Initial amount of tokens for you."}' -p eosio), allow_error: true
    its(:stderr) { is_expected.to include('missing authority of eosdactoken') }
  end

  context "with valid auth should succeed" do
    command %(cleos push action eosdactoken issue '{ "to": "eosdactoken", "quantity": "1000.0000 ABC", "memo": "Initial amount of tokens for you."}' -p eosdactoken), allow_error: true
    its(:stdout) { is_expected.to include('eosdactoken::issue') }
  end

  context "greater than max should fail" do
    command %(cleos push action eosdactoken issue '{ "to": "eosdactoken", "quantity": "11000.0000 ABC", "memo": "Initial amount of tokens for you."}' -p eosdactoken), allow_error: true
    its(:stderr) { is_expected.to include('quantity exceeds available supply') }
  end

  context "for inflation with valid auth should succeed" do
    command %(cleos push action eosdactoken issue '{ "to": "eosdactoken", "quantity": "2000.0000 ABC", "memo": "Initial amount of tokens for you."}' -p eosdactoken), allow_error: true
    its(:stdout) { is_expected.to include('eosdactoken::issue') }
  end
end

describe "Read back the stats after issuing currency should display max supply, supply and issuer" do
  command %(cleos get currency stats eosdactoken ABC), allow_error: true
  it do
    expect(JSON.parse(subject.stdout)).to eq JSON.parse <<~JSON
    {
      "ABC": {
        "supply": "3000.0000 ABC",
        "max_supply": "10000.0000 ABC",
        "issuer": "eosdactoken"
      }
    }
    JSON
  end
end

describe "Transfer some tokens" do
  context "without auth should fail" do
    command %(cleos push action eosdactoken transfer '{ "from": "eosdactoken", "to": "eosio", "quantity": "500.0000 ABC", "memo": "my first transfer"}'), allow_error: true
    its(:stderr) { is_expected.to include('transaction must have at least one authorization') }
  end

  context "with mismatching auth should fail" do
    command %(cleos push action eosdactoken transfer '{ "from": "eosdactoken", "to": "eosio", "quantity": "500.0000 ABC", "memo": "my first transfer"}' -p eosio), allow_error: true
    its(:stderr) { is_expected.to include('missing authority of eosdactoken') }
  end

  context "with valid auth should succeed" do
    command %(cleos push action eosdactoken transfer '{ "from": "eosdactoken", "to": "eosio", "quantity": "500.0000 ABC", "memo": "my first transfer"}' --permission eosdactoken@active), allow_error: true
    its(:stdout) { is_expected.to include('500.0000 ABC') }
  end

  context "with amount greater than balance should fail" do
    command %(cleos push action eosdactoken transfer '{ "from": "eosio", "to": "eosdactoken", "quantity": "50000.0000 ABC", "memo": "my first transfer"}' -p eosio), allow_error: true
    its(:stderr) { is_expected.to include('overdrawn balance') }
  end
end

describe "Read back the result balance" do
  command %(cleos get currency balance eosdactoken eosdactoken), allow_error: true
  its(:stdout) { is_expected.to include('500.0000 ABC') }

end

describe "Burn tokens" do
  context "more than available supply should fail" do
    command %(cleos push action eosdactoken burn '{ "quantity": "9500.0000 ABC"}' -p eosdactoken), allow_error: true
    its(:stderr) { is_expected.to include('burn quantity exceeds available supply') }
  end

  context "without auth should fail" do
    command %(cleos push action eosdactoken burn '{ "quantity": "500.0000 ABC"}'), allow_error: true
    its(:stderr) { is_expected.to include('transaction must have at least one authorization') }
  end

  context "with wrong auth should fail" do
    command %(cleos push action eosdactoken burn '{ "quantity": "500.0000 ABC"}' -p eosio), allow_error: true
    its(:stderr) { is_expected.to include('missing authority of eosdactoken') }
  end

  context "with legal amount of tokens should succeed" do
    command %(cleos push action eosdactoken burn '{ "quantity": "500.0000 ABC"}' -p eosdactoken), allow_error: true
    its(:stdout) { is_expected.to include('eosdactoken::burn') }
  end
end

describe "Stats and max supply should be less now" do
  command %(cleos get currency stats eosdactoken ABC), allow_error: true
end

describe "Member reg" do
  context "without auth should fail" do
    command %(cleos push action eosdactoken memberreg '{ "sender": "eosio", "agreedterms": "initaltermsagreedbyuser"}'), allow_error: true
    its(:stderr) { is_expected.to include('transaction must have at least one authorization') }
  end

  context "with mismatching auth should fail" do
    command %(cleos push action eosdactoken memberreg '{ "sender": "eosio", "agreedterms": "initaltermsagreedbyuser"}' -p eosdactoken), allow_error: true
    its(:stderr) { is_expected.to include('missing authority of eosio') }
  end

  context "with valid auth for second account should succeed" do
    command %(cleos push action eosdactoken memberreg '{ "sender": "tester1", "agreedterms": "initaltermsagreedbyuser"}' -p tester1), allow_error: true
    its(:stdout) { is_expected.to include('eosdactoken::memberreg') }
  end

  context "with valid auth for should succeed" do
    command %(cleos push action eosdactoken memberreg '{ "sender": "eosio", "agreedterms": "initaltermsagreedbyuser"}' -p eosio), allow_error: true
    its(:stdout) { is_expected.to include('eosdactoken::memberreg') }
  end

  describe "Read back the result for regmembers hasagreed should have two accounts" do
    command %(cleos get table eosdactoken eosdactoken members), allow_error: true
    it do
      expect(JSON.parse(subject.stdout)).to eq JSON.parse <<~JSON
      {
        "rows": [{
          "sender": "eosio",
          "agreedterms": "initaltermsagreedbyuser"
          },{
            "sender": "tester1",
            "agreedterms": "initaltermsagreedbyuser"
          }
        ],
        "more": false
      }
      JSON
    end
  end
end

describe "Update existing member reg" do
  context "without auth should fail" do
    command %(cleos push action eosdactoken memberreg '{ "sender": "eosio", "agreedterms": "subsequenttermsagreedbyuser"}'), allow_error: true
    its(:stderr) { is_expected.to include('transaction must have at least one authorization') }
  end

  context "with mismatching auth should fail" do
    command %(cleos push action eosdactoken memberreg '{ "sender": "eosio", "agreedterms": "subsequenttermsagreedbyuser"}' -p eosdactoken), allow_error: true
    its(:stderr) { is_expected.to include('missing authority of eosio') }
  end

  context "with valid auth" do
    command %(cleos push action eosdactoken memberreg '{ "sender": "eosio", "agreedterms": "subsequenttermsagreedbyuser"}' -p eosio@active), allow_error: true
    its(:stdout) { is_expected.to include('eosdactoken::memberreg') }
  end
end

describe "Read back the result for regmembers hasagreed should maybe be 1" do
  command %(cleos get table eosdactoken eosdactoken members), allow_error: true
  it do
    expect(JSON.parse(subject.stdout)).to eq JSON.parse <<~JSON
    {
      "rows": [{
        "sender": "eosio",
        "agreedterms": "subsequenttermsagreedbyuser"
        },{
          "sender": "tester1",
          "agreedterms": "initaltermsagreedbyuser"
        }
      ],
      "more": false
    }
    JSON
  end
end

describe "Unregister existing member" do
  context "without correct auth" do
    command %(cleos push action eosdactoken memberunreg '{ "sender": "eosio"}'), allow_error: true
    its(:stderr) { is_expected.to include('transaction must have at least one authorization') }
  end

  context "with mismatching auth" do
    command %(cleos push action eosdactoken memberunreg '{ "sender": "eosio"}' -p currency@active), allow_error: true
    its(:stderr) { is_expected.to include('but does not have signatures for it') }
  end

  context "with correct auth" do
    command %(cleos push action eosdactoken memberunreg '{ "sender": "eosio"}' -p eosio@active), allow_error: true
    its(:stdout) { is_expected.to include('eosdactoken::memberunreg') }
  end
end

  describe "Read back the result for regmembers has agreed should be 0" do
    command %(cleos get table eosdactoken eosdactoken members), allow_error: true
    it do
      expect(JSON.parse(subject.stdout)).to eq JSON.parse <<-JSON
      {
        "rows": [{
          "sender": "tester1",
          "agreedterms": "initaltermsagreedbyuser"
        }
      ],
      "more": false
    }
    JSON
  end
end
