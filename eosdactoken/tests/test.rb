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

describe "Prepare for test run from a clean chain" do
    puts `eosio_helpers_create_and_unlock_account.sh`
    puts `eosio_helpers_compile_and_upload.sh`
    puts `ruby tests/create_accounts.rb`
end

describe "Create a new currency" do
  context "without account auth should fail" do
    command %(cleos push action eosdactoken create '{ "issuer": "eosdactoken", "maximum_supply": "10000.0000 ABY", "transfer_locked": false}'), allow_error: true
    its(:stderr) { is_expected.to include('transaction must have at least one authorization') }
  end

  context "with mismatching auth should fail" do
    command %(cleos push action eosdactoken create '{ "issuer": "eosdactoken", "maximum_supply": "10000.0000 ABY", "transfer_locked": false}' -p eosio), allow_error: true
    its(:stderr) { is_expected.to include('missing authority of eosdactoken') }
  end

  context "with matching issuer and account auth should succeed." do
    command %(cleos push action eosdactoken create '{ "issuer": "eosdactoken", "maximum_supply": "10000.0000 ABY", "transfer_locked": false}' -p eosdactoken), allow_error: true
    its(:stdout) { is_expected.to include('eosdactoken::create') }
  end
end

context "Locked Tokens - " do
  context "Create with transfer_locked true" do
    context "create new token should succeed" do
      command %(cleos push action eosdactoken create '{ "issuer": "eosdactoken", "maximum_supply": "10000.0000 ABP", "transfer_locked": true}' -p eosdactoken), allow_error: true
      its(:stdout) { is_expected.to include('eosdactoken::create') }
    end

    context "Issue tokens with valid auth should succeed" do
        command %(cleos push action eosdactoken issue '{ "to": "eosdactoken", "quantity": "1000.0000 ABP", "memo": "Initial amount of tokens for you."}' -p eosdactoken), allow_error: true
        its(:stdout) { is_expected.to include('eosdactoken::issue') }
      end
    end

    context "Transfer with valid issuer auth from locked token should succeed" do
        command %(cleos push action eosdactoken transfer '{ "from": "eosdactoken", "to": "eosio", "quantity": "500.0000 ABP", "memo": "my first transfer"}' --permission eosdactoken@active), allow_error: true
        its(:stdout) { is_expected.to include('500.0000 ABP') }
      end


    context "Transfer from locked token with non-issuer auth should fail" do
        command %(cleos push action eosdactoken transfer '{ "from": "1..kgbxghfkr", "to": "eosdactoken", "quantity": "400.0000 ABP", "memo": "my second transfer"}' -p 1..kgbxghfkr), allow_error: true
        its(:stderr) { is_expected.to include('Ensure that you have the related authority inside your transaction!') }
      end

      context "Unlock locked token with non-issuer auth should fail" do
        command %(cleos push action eosdactoken unlock '{ "unlock": "10000.0000 ABP"}' -p 1..kgbxghfkr), allow_error: true
        its(:stderr) { is_expected.to include('missing authority of eosdactoken') }
      end

    context "Transfer from locked token with non-issuer auth should fail after failed unlock attempt" do
        command %(cleos push action eosdactoken transfer '{ "from": "eosio", "to": "eosdactoken", "quantity": "400.0000 ABP", "memo": "my second transfer"}' -p eosio), allow_error: true
        its(:stderr) { is_expected.to include('missing authority of eosdactoken') }
      end

    context "Unlock locked token with issuer auth should succeed" do
        command %(cleos push action eosdactoken unlock '{ "unlock": "1.0 ABP"}' -p eosdactoken), allow_error: true
        its(:stdout) { is_expected.to include('{"unlock":"1.0 ABP"}') }
    end

    context "Transfer from unlocked token with non-issuer auth should succeed after successful unlock" do
        command %(cleos push action eosdactoken transfer '{ "from": "eosio", "to": "eosdactoken", "quantity": "400.0000 ABP", "memo": "my second transfer"}' -p eosio), allow_error: true
        its(:stdout) { is_expected.to include('400.0000 ABP') }
    end

    context "Read the stats after issuing currency should display supply, supply and issuer" do
        command %(cleos get currency stats eosdactoken ABP), allow_error: true
        it do
          expect(JSON.parse(subject.stdout)).to eq JSON.parse <<~JSON
          {
            "ABP": {
              "supply": "1000.0000 ABP",
              "max_supply": "10000.0000 ABP",
              "issuer": "eosdactoken"
            }
          }
          JSON
        end
      end
end

describe "Issue new currency" do
  context "without valid auth should fail" do
    command %(cleos push action eosdactoken issue '{ "to": "eosdactoken", "quantity": "1000.0000 ABY", "memo": "Initial amount of tokens for you."}'), allow_error: true
    its(:stderr) { is_expected.to include('transaction must have at least one authorization') }
  end

  context "without owner auth should fail" do
    command %(cleos push action eosdactoken issue '{ "to": "tester1", "quantity": "1000.0000 ABY", "memo": "Initial amount of tokens for you."} -p tester1'), allow_error: true
    its(:stderr) { is_expected.to include('transaction must have at least one authorization') }
  end

  context "with mismatching auth should fail" do
    command %(cleos push action eosdactoken issue '{ "to": "eosdactoken", "quantity": "1000.0000 ABY", "memo": "Initial amount of tokens for you."}' -p eosio), allow_error: true
    its(:stderr) { is_expected.to include('missing authority of eosdactoken') }
  end

  context "with valid auth should succeed" do
    command %(cleos push action eosdactoken issue '{ "to": "eosdactoken", "quantity": "1000.0000 ABY", "memo": "Initial amount of tokens for you."}' -p eosdactoken), allow_error: true
    its(:stdout) { is_expected.to include('eosdactoken::issue') }
  end

  context "greater than max should fail" do
    command %(cleos push action eosdactoken issue '{ "to": "eosdactoken", "quantity": "11000.0000 ABY", "memo": "Initial amount of tokens for you."}' -p eosdactoken), allow_error: true
    its(:stderr) { is_expected.to include('quantity exceeds available supply') }
  end

  context "for inflation with valid auth should succeed" do
    command %(cleos push action eosdactoken issue '{ "to": "eosdactoken", "quantity": "2000.0000 ABY", "memo": "Initial amount of tokens for you."}' -p eosdactoken), allow_error: true
    its(:stdout) { is_expected.to include('eosdactoken::issue') }
  end
end

describe "Read back the stats after issuing currency should display max supply, supply and issuer" do
  command %(cleos get currency stats eosdactoken ABY), allow_error: true
  it do
    expect(JSON.parse(subject.stdout)).to eq JSON.parse <<~JSON
    {
      "ABY": {
        "supply": "3000.0000 ABY",
        "max_supply": "10000.0000 ABY",
        "issuer": "eosdactoken"
      }
    }
    JSON
  end
end

describe "Transfer some tokens" do
  context "without auth should fail" do
    command %(cleos push action eosdactoken transfer '{ "from": "eosdactoken", "to": "eosio", "quantity": "500.0000 ABY", "memo": "my first transfer"}'), allow_error: true
    its(:stderr) { is_expected.to include('transaction must have at least one authorization') }
  end

  context "with mismatching auth should fail" do
    command %(cleos push action eosdactoken transfer '{ "from": "eosdactoken", "to": "eosio", "quantity": "500.0000 ABY", "memo": "my first transfer"}' -p eosio), allow_error: true
    its(:stderr) { is_expected.to include('missing authority of eosdactoken') }
  end

  context "with valid auth should succeed" do
    command %(cleos push action eosdactoken transfer '{ "from": "eosdactoken", "to": "eosio", "quantity": "500.0000 ABY", "memo": "my first transfer"}' --permission eosdactoken@active), allow_error: true
    its(:stdout) { is_expected.to include('500.0000 ABY') }
  end

  context "with amount greater than balance should fail" do
    command %(cleos push action eosdactoken transfer '{ "from": "eosio", "to": "eosdactoken", "quantity": "50000.0000 ABY", "memo": "my first transfer"}' -p eosio), allow_error: true
    its(:stderr) { is_expected.to include('overdrawn balance') }
  end
end

describe "Read back the result balance" do
  command %(cleos get currency balance eosdactoken eosdactoken), allow_error: true
  its(:stdout) { is_expected.to include('500.0000 ABY') }

end

describe "Unlock tokens" do
    context "without auth should fail" do
      command %(cleos push action eosdactoken unlock '{"unlock": "9500.0000 ABP"}'), allow_error: true
      its(:stderr) { is_expected.to include('transaction should have at least one required authority') }
    end

    context "with auth should succeed" do
        puts `cleos push action eosdactoken create '{ "issuer": "eosdactoken", "maximum_supply": "10000.0000 ABX", "transfer_locked": true}' -p eosdactoken`
        command %(cleos push action eosdactoken unlock '{"unlock": "9500.0000 ABX"}' -p eosdactoken), allow_error: true
        its(:stdout) { is_expected.to include('eosdactoken <= eosdactoken::unlock') }
    end
end

describe "Burn tokens" do
  context "before unlocking token should fail" do
    puts `cleos push action eosdactoken create '{ "issuer": "eosdactoken", "maximum_supply": "10000.0000 ABZ", "transfer_locked": true}' -p eosdactoken`
    command %(cleos push action eosdactoken burn '{"from": "eosdactoken", "quantity": "9500.0000 ABZ"}' -p eosdactoken), allow_error: true
    its(:stderr) { is_expected.to include('Burn tokens on transferLocked token. The issuer must `unlock` first') }
  end

  context "After unlocking token" do
    before do
        puts `cleos push action eosdactoken unlock '{"unlock": "9500.0000 ABP"}' -p eosdactoken`
    end

    context "more than available supply should fail" do
        before do
            puts `cleos push action eosdactoken transfer '{"from": "eosdactoken", "to": "testuser1", "quantity": "900.0000 ABP", "memo": "anything"}' -p eosdactoken`
        end
        command %(cleos push action eosdactoken burn '{"from": "testuser1", "quantity": "9600.0000 ABP"}' -p testuser1), allow_error: true
        its(:stderr) { is_expected.to include('overdrawn balance') }
    end

    context "without auth should fail" do
        command %(cleos push action eosdactoken burn '{ "from": "eosdactoken","quantity": "500.0000 ABP"}'), allow_error: true
        its(:stderr) { is_expected.to include('transaction must have at least one authorization') }
    end

    context "with wrong auth should fail" do
        command %(cleos push action eosdactoken burn '{"from": "eosdactoken", "quantity": "500.0000 ABP"}' -p eosio), allow_error: true
        its(:stderr) { is_expected.to include('missing authority of eosdactoken') }
    end

    context "with legal amount of tokens should succeed" do
        command %(cleos push action eosdactoken burn '{"from": "testuser1", "quantity": "90.0000 ABP"}' -p testuser1), allow_error: true
        its(:stdout) { is_expected.to include('eosdactoken::burn') }
    end
  end
end

describe "Read back the stats after burning currency should display reduced supply, same max supply and issuer" do
    command %(cleos get currency stats eosdactoken ABP), allow_error: true
    it do
      expect(JSON.parse(subject.stdout)).to eq JSON.parse <<~JSON
      {
        "ABP": {
          "supply": "910.0000 ABP",
          "max_supply": "10000.0000 ABP",
          "issuer": "eosdactoken"
        }
      }
      JSON
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
