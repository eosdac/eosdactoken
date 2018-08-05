require 'rspec_command'
require "json"


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

CONTRACT_OWNER_PRIVATE_KEY='5K86iZz9h8jwgGDttMPcHqFHHru5ueqnfDs5fVSHfm8bJt8PjK6'
CONTRACT_OWNER_PUBLIC_KEY='EOS6Y1fKGLVr2zEFKKfAmRUoH1LzM7crJEBi4dL5ikYeGYqiJr6SS'

CONTRACT_ACTIVE_PRIVATE_KEY='5Jbf3f26fz4HNWXVAd3TMYHnC68uu4PtkMnbgUa5mdCWmgu47sR'
CONTRACT_ACTIVE_PUBLIC_KEY='EOS7rjn3r52PYd2ppkVEKYvy6oRDP9MZsJUPB2MStrak8LS36pnTZ'

CONTRACT_NAME='eosdactoken'
ACCOUNT_NAME='eosdactoken'

beforescript = <<~SHELL
  set -x
  kill -INT `pgrep nodeos`
  nodeos --delete-all-blocks  &>/dev/null &
  sleep 2.0
  cleos wallet unlock --password `cat ~/eosio-wallet/.pass`
  cleos wallet import --private-key #{CONTRACT_ACTIVE_PRIVATE_KEY}
  cleos create account eosio #{ACCOUNT_NAME} #{CONTRACT_OWNER_PUBLIC_KEY} #{CONTRACT_ACTIVE_PUBLIC_KEY} -j

  # create accounts for tests
  cleos create account eosio testuser1 #{CONTRACT_OWNER_PUBLIC_KEY} #{CONTRACT_ACTIVE_PUBLIC_KEY} -j
  cleos create account eosio testuser2 #{CONTRACT_OWNER_PUBLIC_KEY} #{CONTRACT_ACTIVE_PUBLIC_KEY} -j
  cleos create account eosio testuser3 #{CONTRACT_OWNER_PUBLIC_KEY} #{CONTRACT_ACTIVE_PUBLIC_KEY} -j

  if [[ $? != 0 ]] 
    then 
    echo "Failed to create contract account" 
    exit 1
  fi
  # eosio-cpp -g #{CONTRACT_NAME}.abi #{CONTRACT_NAME}.cpp
  # eosio-cpp -o #{CONTRACT_NAME}.wast *.cpp -v
  if [[ $? != 0 ]] 
    then 
    echo "failed to compile contract" 
    exit 1
  fi
  cd ..
  cleos set contract #{ACCOUNT_NAME} #{CONTRACT_NAME} -p #{ACCOUNT_NAME} -j
  echo `pwd`

SHELL


describe "eosdactoken" do
  before(:all) do
    `#{beforescript}`
    exit() unless $? == 0
  end

  context "Seed accounts for tests" do
    it {expect(true)}
  end
end

describe "Create a new currency" do
  context "without account auth should fail" do
    command %(cleos push action eosdactoken create '{ "issuer": "eosdactoken", "maximum_supply": "10000.0000 ABY", "transfer_locked": false}'), allow_error: true
    its(:stderr) { is_expected.to include('Error 3040003') }
  end

  context "with mismatching auth should fail" do
    command %(cleos push action eosdactoken create '{ "issuer": "eosdactoken", "maximum_supply": "10000.0000 ABY", "transfer_locked": false}' -p eosio), allow_error: true
    its(:stderr) { is_expected.to include('Error 3090004') }
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
        command %(cleos push action eosdactoken transfer '{ "from": "tester3", "to": "eosdactoken", "quantity": "400.0000 ABP", "memo": "my second transfer"}' -p tester3), allow_error: true
        its(:stderr) { is_expected.to include('Ensure that you have the related private keys inside your wallet and your wallet is unlocked.') }
      end

      context "Unlock locked token with non-issuer auth should fail" do
        command %(cleos push action eosdactoken unlock '{ "unlock": "10000.0000 ABP"}' -p tester3), allow_error: true
        its(:stderr) { is_expected.to include('Ensure that you have the related private keys inside your wallet and your wallet is unlocked') }
      end

    context "Transfer from locked token with non-issuer auth should fail after failed unlock attempt" do
        command %(cleos push action eosdactoken transfer '{ "from": "eosio", "to": "eosdactoken", "quantity": "400.0000 ABP", "memo": "my second transfer"}' -p eosio), allow_error: true
        its(:stderr) { is_expected.to include('Error 3090004') }
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
    its(:stderr) { is_expected.to include('Transaction should have at least one required authority') }
  end

  context "without owner auth should fail" do
    command %(cleos push action eosdactoken issue '{ "to": "tester1", "quantity": "1000.0000 ABY", "memo": "Initial amount of tokens for you."} -p tester1'), allow_error: true
    its(:stderr) { is_expected.to include('Transaction should have at least one required authority') }
  end

  context "with mismatching auth should fail" do
    command %(cleos push action eosdactoken issue '{ "to": "eosdactoken", "quantity": "1000.0000 ABY", "memo": "Initial amount of tokens for you."}' -p eosio), allow_error: true
    its(:stderr) { is_expected.to include('Error 3090004') }
  end

  context "with valid auth should succeed" do
    command %(cleos push action eosdactoken issue '{ "to": "eosdactoken", "quantity": "1000.0000 ABY", "memo": "Initial amount of tokens for you."}' -p eosdactoken), allow_error: true
    its(:stdout) { is_expected.to include('eosdactoken::issue') }
  end

  context "greater than max should fail" do
    command %(cleos push action eosdactoken issue '{ "to": "eosdactoken", "quantity": "11000.0000 ABY", "memo": "Initial amount of tokens for you."}' -p eosdactoken), allow_error: true
    its(:stderr) { is_expected.to include('Error 3050003') }
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
    its(:stderr) { is_expected.to include('Transaction should have at least one required authority') }
  end

  context "with mismatching auth should fail" do
    command %(cleos push action eosdactoken transfer '{ "from": "eosdactoken", "to": "eosio", "quantity": "500.0000 ABY", "memo": "my first transfer"}' -p eosio), allow_error: true
    its(:stderr) { is_expected.to include('Error 3090004') }
  end

  context "with valid auth should succeed" do
    command %(cleos push action eosdactoken transfer '{ "from": "eosdactoken", "to": "eosio", "quantity": "500.0000 ABY", "memo": "my first transfer"}' --permission eosdactoken@active), allow_error: true
    its(:stdout) { is_expected.to include('500.0000 ABY') }
  end

  context "with amount greater than balance should fail" do
    command %(cleos push action eosdactoken transfer '{ "from": "eosio", "to": "eosdactoken", "quantity": "50000.0000 ABY", "memo": "my first transfer"}' -p eosio), allow_error: true
    its(:stderr) { is_expected.to include('Error 3050003') }
  end
end

describe "Read back the result balance" do
  command %(cleos get currency balance eosdactoken eosdactoken), allow_error: true
  its(:stdout) { is_expected.to include('500.0000 ABY') }

end

describe "Unlock tokens" do
    context "without auth should fail" do
      command %(cleos push action eosdactoken unlock '{"unlock": "9500.0000 ABP"}'), allow_error: true
      its(:stderr) { is_expected.to include('Error 3040003') }
    end

    context "with auth should succeed" do
      before do
          puts `cleos push action eosdactoken create '{ "issuer": "eosdactoken", "maximum_supply": "10000.0000 ABX", "transfer_locked": true}' -p eosdactoken`
      end
        command %(cleos push action eosdactoken unlock '{"unlock": "9500.0000 ABX"}' -p eosdactoken), allow_error: true
        its(:stdout) { is_expected.to include('eosdactoken <= eosdactoken::unlock') }
    end
end

describe "Burn tokens" do
  context "before unlocking token should fail" do
    before do
      puts `cleos push action eosdactoken create '{ "issuer": "eosdactoken", "maximum_supply": "10000.0000 ABZ", "transfer_locked": true}' -p eosdactoken`
    end
    command %(cleos push action eosdactoken burn '{"from": "eosdactoken", "quantity": "9500.0000 ABZ"}' -p eosdactoken), allow_error: true
    its(:stderr) { is_expected.to include('Error 3050003') }
  end

  context "After unlocking token" do
    before(:all) do
        puts `cleos push action eosdactoken unlock '{"unlock": "9500.0000 ABP"}' -p eosdactoken`
    end

    context "more than available supply should fail" do
        before do
            puts `cleos push action eosdactoken transfer '{"from": "eosdactoken", "to": "testuser1", "quantity": "900.0000 ABP", "memo": "anything"}' -p eosdactoken`
        end
        command %(cleos push action eosdactoken burn '{"from": "testuser1", "quantity": "9600.0000 ABP"}' -p testuser1), allow_error: true
        its(:stderr) { is_expected.to include('Error 3050003') }
    end

    context "without auth should fail" do
        command %(cleos push action eosdactoken burn '{ "from": "eosdactoken","quantity": "500.0000 ABP"}'), allow_error: true
        its(:stderr) { is_expected.to include('Transaction should have at least one required authority') }
    end

    context "with wrong auth should fail" do
        command %(cleos push action eosdactoken burn '{"from": "eosdactoken", "quantity": "500.0000 ABP"}' -p eosio), allow_error: true
        its(:stderr) { is_expected.to include('Error 3090004') }
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

describe "newmemterms" do
  context "without valid auth" do
    command %(cleos push action eosdactoken newmemterms '{ "terms": "New Latest terms", "hash": "termshashsdsdsd"}' -p tester1), allow_error: true
    its(:stderr) { is_expected.to include('Ensure that you have the related private keys inside your wallet and your wallet is unlocked') }
  end

  context "without empty terms" do
    command %(cleos push action eosdactoken newmemterms '{ "terms": "", "hash": "termshashsdsdsd"}' -p eosdactoken), allow_error: true
    its(:stderr) { is_expected.to include('Error 3050003') }
  end

  context "with long terms" do
    command %(cleos push action eosdactoken newmemterms '{ "terms": "aasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdf", "hash": "termshashsdsdsd"}' -p eosdactoken), allow_error: true
    its(:stderr) { is_expected.to include('Error 3050003') }
  end

  context "without empty hash" do
    command %(cleos push action eosdactoken newmemterms '{ "terms": "normallegalterms", "hash": ""}' -p eosdactoken), allow_error: true
    its(:stderr) { is_expected.to include('Error 3050003') }
  end

  context "with long hash" do
    command %(cleos push action eosdactoken newmemterms '{ "terms": "normallegalterms", "hash": "asdfasdfasdfasdfasdfasdfasdfasdfl"}' -p eosdactoken), allow_error: true
    its(:stderr) { is_expected.to include('Error 3050003') }
  end

  context "with valid terms and hash" do
    command %(cleos push action eosdactoken newmemterms '{ "terms": "normallegalterms", "hash": "asdfasdfasdfasdfasdfasd"}' -p eosdactoken), allow_error: true
    its(:stdout) { is_expected.to include('eosdactoken <= eosdactoken::newmemterms') }
  end


end

describe "Member reg" do
  before(:all) do
  puts "before stufff"
  end

  context "without auth should fail" do
    command %(cleos push action eosdactoken memberreg '{ "sender": "eosio", "agreedterms": "New Latest terms"}'), allow_error: true
    its(:stderr) { is_expected.to include('Transaction should have at least one required authority') }
  end

  context "with mismatching auth should fail" do
    command %(cleos push action eosdactoken memberreg '{ "sender": "eosio", "agreedterms": "New Latest terms"}' -p eosdactoken), allow_error: true
    its(:stderr) { is_expected.to include('Error 3090004') }
  end

  context "with valid auth for second account should succeed" do
    command %(cleos push action eosdactoken memberreg '{ "sender": "testuser2", "agreedterms": "asdfasdfasdfasdfasdfasd"}' -p testuser2), allow_error: true
    its(:stdout) { is_expected.to include('eosdactoken::memberreg') }
  end

  describe "Read back the result for regmembers hasagreed should have two accounts", focus: true do
    command %(cleos get table eosdactoken eosdactoken members), allow_error: true
    it do
      expect(JSON.parse(subject.stdout)).to eq JSON.parse <<~JSON
      {
        "rows": [
          {"sender":"testuser2", "agreedterms":1}
        ],
        "more": false
      }
      JSON
    end
  end
end

describe "Update existing member reg" do
  before(:all) do 
    puts `cleos push action eosdactoken newmemterms '{ "terms": "normallegalterms2", "hash": "dfghdfghdfghdfghdfg"}' -p eosdactoken`
  end
  
  context "without auth should fail" do
    command %(cleos push action eosdactoken memberreg '{ "sender": "tester3", "agreedterms": "subsequenttermsagreedbyuser"}'), allow_error: true
    its(:stderr) { is_expected.to include('Transaction should have at least one required authority') }
  end

  context "with mismatching auth should fail" do
    command %(cleos push action eosdactoken memberreg '{ "sender": "tester3", "agreedterms": "subsequenttermsagreedbyuser"}' -p eosdactoken), allow_error: true
    its(:stderr) { is_expected.to include('Error 3090004') }
  end

  context "with valid auth" do
    command %(cleos push action eosdactoken memberreg '{ "sender": "testuser3", "agreedterms": "dfghdfghdfghdfghdfg"}' -p testuser3@active), allow_error: true
    its(:stdout) { is_expected.to include('eosdactoken::memberreg') }
  end
end

describe "Read back the result for regmembers hasagreed should have entry" do
  command %(cleos get table eosdactoken eosdactoken members), allow_error: true
  it do
    expect(JSON.parse(subject.stdout)).to eq JSON.parse <<~JSON
    {
      "rows": [
        {"sender":"testuser2", "agreedterms":1},
        {"sender":"testuser3", "agreedterms":2}
      ],
      "more": false
    }
    JSON
  end
end

describe "Unregister existing member" do
  context "without correct auth" do
    command %(cleos push action eosdactoken memberunreg '{ "sender": "testuser3"}'), allow_error: true
    its(:stderr) { is_expected.to include('Transaction should have at least one required authority') }
  end

  context "with mismatching auth" do
    command %(cleos push action eosdactoken memberunreg '{ "sender": "testuser3"}' -p currency@active), allow_error: true
    its(:stderr) { is_expected.to include('Error 3090003') }
  end

  context "with correct auth" do
    command %(cleos push action eosdactoken memberunreg '{ "sender": "testuser3"}' -p testuser3@active), allow_error: true
    its(:stdout) { is_expected.to include('eosdactoken::memberunreg') }
  end
end

describe "Read back the result for regmembers has agreed should be 0" do
  command %(cleos get table eosdactoken eosdactoken members), allow_error: true
  it do
    expect(JSON.parse(subject.stdout)).to eq JSON.parse <<-JSON
    {
      "rows": [
        {"sender":"testuser2", "agreedterms":1}
    ],
    "more": false
  }
  JSON
end
end
