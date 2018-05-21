require 'rspec_command'
require "json"
require_relative './accounts_helper'


# 1. A recent version of Ruby is required
# 2. Ensure the required gems are installed with `gem install rspec json rspec-command`
# 3. Run this from the command line with rspec test.rb

# Optionally output the test results with -f [p|d|h] for required views of the test results.

# For debugging I added a clear action to the contract which clears everything in the tables
# for a "clean" contract environment but this should not be shipped with the production code.

# For these tests to pass there must be accounts with keys added for eosdactoken, tester1 and tester3 first.
# owner

RSpec.configure do |config|
  config.include RSpecCommand
end

describe "Clear all tables first (only for debugging and testing)" do
  command  %(cleos push action eosdactoken clear '{ "sym": "1.0 ABC", "owner": "eosdactoken"}' -p eosio), allow_error: true
  its(:stdout) { is_expected.to include('eosdactoken::clear') }
  # its(:stderr) { is_expected.to be_nil() }
end

describe "Create a new currency" do
  context "without account auth should fail" do
    command %(cleos push action eosdactoken create '{ "issuer": "eosdactoken", "maximum_supply": "10000.0000 ABC"}'), allow_error: true
    its(:stderr) { is_expected.to include('transaction must have at least one authorization') }
  end

  context "with mismatching auth should fail" do
    command %(cleos push action eosdactoken create '{ "issuer": "eosdactoken", "maximum_supply": "10000.0000 ABC"}' -p eosio), allow_error: true
    its(:stderr) { is_expected.to include('missing authority of eosdactoken') }
  end

  context "with matching issuer and account auth should succeed." do
    command %(cleos push action eosdactoken create '{ "issuer": "eosdactoken", "maximum_supply": "10000.0000 ABC"}' -p eosdactoken), allow_error: true
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

describe "Member add" do
  context "without owner auth" do
    command %(cleos push action eosdactoken memberadd '{ "newmember": ".1.kgbxghfkr", "quantity": "500.0000 ABC", "memo": "air drop balance"}'), allow_error: true
    its(:stderr) { is_expected.to include('transaction must have at least one authorization') }
  end

  context "with owner auth" do
    command %(cleos push action eosdactoken memberadd '[".1.kgbxghfkr", "500.0000 ABC", "air drop balance"]' -p eosdactoken), allow_error: true
    its(:stdout) { is_expected.to include('eosdactoken::memberadd') }
  end
end

describe "Member add array" do

  context "without owner auth" do
    command %(cleos push action eosdactoken memberadda '[[["1..kgbxghfkr", "500.0000 ABC", "air drop balance"]],"memo string"]'), allow_error: true
    its(:stderr) { is_expected.to include('transaction must have at least one authorization') }
  end

  context "with owner auth" do
    command %(cleos push action eosdactoken memberadda '{"newmembers":[{"sender":"2..kgbxghfkr", "quantity":"500.0000 ABC"},{"sender":"3..kgbxghfkr", "quantity":"500.0000 ABC"}], "memo":"air drop balance"}' -p eosdactoken), allow_error: true
    its(:stdout) { is_expected.to include('eosdactoken::memberadda') }
  end

  context "with owner auth array params", focus: true do
    command %(cleos push action eosdactoken memberadda '{"newmembers":[["4..kgbxghfkr", "51.0000 ABC"],["5..kgbxghfkr", "45.0000 ABC"],["a..kgbxghfkr", "12.0000 ABC"],["b..kgbxghfkr", "54.0000 ABC"],["c..kgbxghfkr", "14.0000 ABC"],["d..kgbxghfkr", "75.0000 ABC"]], "memo":"air drop balance"}' -p eosdactoken), allow_error: true
    its(:stdout) { is_expected.to include('eosdactoken::memberadda') }
  end

  context "with owner auth array params as large array", focus: true do
    accounts = generate_account_names 10

    params = accounts.each_with_index.map { |acc, i| %(["#{acc}", "0.0010 ABC"]) }.join(', ')

    command %(cleos push action eosdactoken memberadda '{"newmembers":[#{params}], "memo":"air drop balance"}' -p eosdactoken), allow_error: true
    its(:stdout) { is_expected.to include('eosdactoken::memberadda') }
  end

  describe "Read back the result after batch adding accounts", focus: true do
    command %(cleos get table eosdactoken eosdactoken members), allow_error: true
    it do
      expect(JSON.parse(subject.stdout)).to eq JSON.parse <<~JSON
      {"rows" : [
        {"sender":".1.kgbxghfkr", "agreedterms":""},
        {"sender":"1..kgbxghfkr", "agreedterms":""},
        {"sender":"2..kgbxghfkr", "agreedterms":""},
        {"sender":"3..kgbxghfkr", "agreedterms":""},
        {"sender":"4..kgbxghfkr", "agreedterms":""},
        {"sender":"5..kgbxghfkr", "agreedterms":""},
        {"sender":"a..kgbxghfkr", "agreedterms":""},
        {"sender":"b..kgbxghfkr", "agreedterms":""},
        {"sender":"c..kgbxghfkr", "agreedterms":""},
        {"sender":"d..kgbxghfkr", "agreedterms":""}
      ],
      "more":true}
      JSON
    end
  end
end

describe "Member reg" do
  before(:all) do
    `cleos push action eosdactoken clear '{ "sym": "1.0 ABC", "owner": "eosdactoken"}' -p eosio`
  end

  context "without auth should fail" do
    command %(cleos push action eosdactoken memberreg '{ "sender": "eosio", "agreedterms": "initaltermsagreedbyuser"}'), allow_error: true
    its(:stderr) { is_expected.to include('transaction must have at least one authorization') }
  end

  context "with mismatching auth should fail" do
    command %(cleos push action eosdactoken memberreg '{ "sender": "eosio", "agreedterms": "initaltermsagreedbyuser"}' -p eosdactoken), allow_error: true
    its(:stderr) { is_expected.to include('missing authority of eosio') }
  end

  context "with valid auth for second account should succeed" do
    command %(cleos push action eosdactoken memberreg '{ "sender": "5..kgbxghfkr", "agreedterms": "initaltermsagreedbyuser"}' -p 5..kgbxghfkr), allow_error: true
    its(:stdout) { is_expected.to include('eosdactoken::memberreg') }
  end

  context "with valid auth for should succeed" do
    command %(cleos push action eosdactoken memberreg '{ "sender": "1..kgbxghfkr", "agreedterms": "initaltermsagreedbyuser"}' -p 1..kgbxghfkr), allow_error: true
    its(:stdout) { is_expected.to include('eosdactoken::memberreg') }
  end

  describe "Read back the result for regmembers hasagreed should have two accounts", focus: true do
    command %(cleos get table eosdactoken eosdactoken members), allow_error: true
    it do
      expect(JSON.parse(subject.stdout)).to eq JSON.parse <<~JSON
      {
        "rows": [
          {"sender":"1..kgbxghfkr", "agreedterms":"initaltermsagreedbyuser"},
          {"sender":"5..kgbxghfkr", "agreedterms":"initaltermsagreedbyuser"}
        ],
        "more": false
      }
      JSON
    end
  end
end

describe "Update existing member reg" do
  context "without auth should fail" do
    command %(cleos push action eosdactoken memberreg '{ "sender": "1..kgbxghfkr", "agreedterms": "subsequenttermsagreedbyuser"}'), allow_error: true
    its(:stderr) { is_expected.to include('transaction must have at least one authorization') }
  end

  context "with mismatching auth should fail" do
    command %(cleos push action eosdactoken memberreg '{ "sender": "1..kgbxghfkr", "agreedterms": "subsequenttermsagreedbyuser"}' -p eosdactoken), allow_error: true
    its(:stderr) { is_expected.to include('missing authority of 1..kgbxghfkr') }
  end

  context "with valid auth" do
    command %(cleos push action eosdactoken memberreg '{ "sender": "1..kgbxghfkr", "agreedterms": "subsequenttermsagreedbyuser"}' -p 1..kgbxghfkr@active), allow_error: true
    its(:stdout) { is_expected.to include('eosdactoken::memberreg') }
  end
end

describe "Read back the result for regmembers hasagreed should have entry" do
  command %(cleos get table eosdactoken eosdactoken members), allow_error: true
  it do
    expect(JSON.parse(subject.stdout)).to eq JSON.parse <<~JSON
    {
      "rows": [
        {"sender":"1..kgbxghfkr", "agreedterms":"subsequenttermsagreedbyuser"},
        {"sender":"5..kgbxghfkr", "agreedterms":"initaltermsagreedbyuser"}
      ],
      "more": false
    }
    JSON
  end
end

describe "Unregister existing member" do
  context "without correct auth" do
    command %(cleos push action eosdactoken memberunreg '{ "sender": "1..kgbxghfkr"}'), allow_error: true
    its(:stderr) { is_expected.to include('transaction must have at least one authorization') }
  end

  context "with mismatching auth" do
    command %(cleos push action eosdactoken memberunreg '{ "sender": "1..kgbxghfkr"}' -p currency@active), allow_error: true
    its(:stderr) { is_expected.to include('but does not have signatures for it') }
  end

  context "with correct auth" do
    command %(cleos push action eosdactoken memberunreg '{ "sender": "1..kgbxghfkr"}' -p 1..kgbxghfkr@active), allow_error: true
    its(:stdout) { is_expected.to include('eosdactoken::memberunreg') }
  end
end

describe "Read back the result for regmembers has agreed should be 0" do
  command %(cleos get table eosdactoken eosdactoken members), allow_error: true
  it do
    expect(JSON.parse(subject.stdout)).to eq JSON.parse <<-JSON
    {
      "rows": [
        {"sender":"5..kgbxghfkr", "agreedterms":"initaltermsagreedbyuser"}
    ],
    "more": false
  }
  JSON
end
end
