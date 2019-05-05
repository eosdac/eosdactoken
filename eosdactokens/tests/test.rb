require 'rspec_command'
require "json"


# 1. A recent version of Ruby is required
# 2. Ensure the required gems are installed with `gem install rspec json rspec-command`
# 3. Run this from the command line with rspec test.rb

# Optionally output the test results with -f [p|d|h] for required views of the test results.

# For debugging I added a clear action to the contract which clears everything in the tables
# for a "clean" contract environment but this should not be shipped with the production code.

# For these tests to pass there must be accounts with keys added for eosdactokens, tester1 and tester3 first.
# owner

RSpec.configure do |config|
  config.include RSpecCommand
end

CONTRACT_OWNER_PRIVATE_KEY = '5K86iZz9h8jwgGDttMPcHqFHHru5ueqnfDs5fVSHfm8bJt8PjK6'
CONTRACT_OWNER_PUBLIC_KEY = 'EOS6Y1fKGLVr2zEFKKfAmRUoH1LzM7crJEBi4dL5ikYeGYqiJr6SS'

CONTRACT_ACTIVE_PRIVATE_KEY = '5Jbf3f26fz4HNWXVAd3TMYHnC68uu4PtkMnbgUa5mdCWmgu47sR'
CONTRACT_ACTIVE_PUBLIC_KEY = 'EOS7rjn3r52PYd2ppkVEKYvy6oRDP9MZsJUPB2MStrak8LS36pnTZ'

CONTRACT_NAME = 'eosdactokens'
ACCOUNT_NAME = 'eosdactokens'

beforescript = <<~SHELL
  set -x

  kill -INT \`pgrep nodeos\`

  # Launch nodeos in a new tab so the output can be observed.
  # ttab is a nodejs module but this could be easily achieved manually without ttab.
   ttab 'nodeos --delete-all-blocks --verbose-http-errors'

  sleep 2.0
  cleos wallet unlock --password `cat ~/eosio-wallet/.pass`
  cleos wallet import --private-key #{CONTRACT_ACTIVE_PRIVATE_KEY}
  cleos create account eosio #{ACCOUNT_NAME} #{CONTRACT_OWNER_PUBLIC_KEY} #{CONTRACT_ACTIVE_PUBLIC_KEY} -j
  cleos create account eosio daccustodian #{CONTRACT_OWNER_PUBLIC_KEY} #{CONTRACT_ACTIVE_PUBLIC_KEY} -j

  # create accounts for tests
  cleos create account eosio testuser1 #{CONTRACT_OWNER_PUBLIC_KEY} #{CONTRACT_ACTIVE_PUBLIC_KEY} -j
  cleos create account eosio testuser2 #{CONTRACT_OWNER_PUBLIC_KEY} #{CONTRACT_ACTIVE_PUBLIC_KEY} -j
  cleos create account eosio testuser3 #{CONTRACT_OWNER_PUBLIC_KEY} #{CONTRACT_ACTIVE_PUBLIC_KEY} -j
  cleos create account eosio otherdacacc #{CONTRACT_OWNER_PUBLIC_KEY} #{CONTRACT_ACTIVE_PUBLIC_KEY} -j

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
  # cd ..
  cleos set contract #{CONTRACT_NAME} output/unit_tests/#{ACCOUNT_NAME} -p #{ACCOUNT_NAME}
  echo `pwd`

SHELL


describe "eosdactokens" do
  before(:all) do
    `#{beforescript}`
    # exit() unless $? == 0
  end

  context "Seed accounts for tests" do
    it {expect(true)}
  end
end

describe "Create a new currency" do
  context "without account auth should fail" do
    command %(cleos push action eosdactokens create '{ "issuer": "eosdactokens", "maximum_supply": "10000.0000 ABY", "transfer_locked": false}'), allow_error: true
    its(:stderr) {is_expected.to include('Error 3040003')}
  end

  context "with mismatching auth should fail" do
    command %(cleos push action eosdactokens create '{ "issuer": "eosdactokens", "maximum_supply": "10000.0000 ABY", "transfer_locked": false}' -p eosio), allow_error: true
    its(:stderr) {is_expected.to include('Error 3090004')}
  end

  context "with matching issuer and account auth should succeed." do
    command %(cleos push action eosdactokens create '{ "issuer": "eosdactokens", "maximum_supply": "10000.0000 ABY", "transfer_locked": false}' -p eosdactokens), allow_error: true
    its(:stdout) {is_expected.to include('eosdactokens::create')}
  end
end

context "Locked Tokens - " do
  context "Create with transfer_locked true" do
    context "create new token should succeed" do
      command %(cleos push action eosdactokens create '{ "issuer": "eosdactokens", "maximum_supply": "10000.0000 ABP", "transfer_locked": true}' -p eosdactokens), allow_error: true
      its(:stdout) {is_expected.to include('eosdactokens::create')}
    end

    context "Issue tokens with valid auth should succeed" do
      command %(cleos push action eosdactokens issue '{ "to": "eosdactokens", "quantity": "1000.0000 ABP", "memo": "Initial amount of tokens for you."}' -p eosdactokens), allow_error: true
      its(:stdout) {is_expected.to include('eosdactokens::issue')}
    end
  end

  context "Transfer with valid issuer auth from locked token should succeed" do
    command %(cleos push action eosdactokens transfer '{ "from": "eosdactokens", "to": "eosio", "quantity": "500.0000 ABP", "memo": "my first transfer"}' --permission eosdactokens@active), allow_error: true
    its(:stdout) {is_expected.to include('500.0000 ABP')}
  end


  context "Transfer from locked token with non-issuer auth should fail" do
    command %(cleos push action eosdactokens transfer '{ "from": "tester3", "to": "eosdactokens", "quantity": "400.0000 ABP", "memo": "my second transfer"}' -p tester3), allow_error: true
    its(:stderr) {is_expected.to include('Ensure that you have the related private keys inside your wallet and your wallet is unlocked.')}
  end

  context "Unlock locked token with non-issuer auth should fail" do
    command %(cleos push action eosdactokens unlock '{ "unlock": "10000.0000 ABP"}' -p tester3), allow_error: true
    its(:stderr) {is_expected.to include('Ensure that you have the related private keys inside your wallet and your wallet is unlocked')}
  end

  context "Transfer from locked token with non-issuer auth should fail after failed unlock attempt" do
    command %(cleos push action eosdactokens transfer '{ "from": "eosio", "to": "eosdactokens", "quantity": "400.0000 ABP", "memo": "my second transfer"}' -p eosio), allow_error: true
    its(:stderr) {is_expected.to include('Error 3090004')}
  end

  context "Unlock locked token with issuer auth should succeed" do
    command %(cleos push action eosdactokens unlock '{ "unlock": "1.0 ABP"}' -p eosdactokens), allow_error: true
    its(:stdout) {is_expected.to include('{"unlock":"1.0 ABP"}')}
  end

  context "Transfer from unlocked token with non-issuer auth should succeed after successful unlock" do
    command %(cleos push action eosdactokens transfer '{ "from": "eosio", "to": "eosdactokens", "quantity": "400.0000 ABP", "memo": "my second transfer"}' -p eosio), allow_error: true
    its(:stdout) {is_expected.to include('400.0000 ABP')}
  end

  context "Read the stats after issuing currency should display supply, supply and issuer" do
    command %(cleos get currency stats eosdactokens ABP), allow_error: true
    it do
      expect(JSON.parse(subject.stdout)).to eq JSON.parse <<~JSON
          {
            "ABP": {
              "supply": "1000.0000 ABP",
              "max_supply": "10000.0000 ABP",
              "issuer": "eosdactokens"
            }
          }
      JSON
    end
  end
end

describe "Issue new currency" do
  context "without valid auth should fail" do
    command %(cleos push action eosdactokens issue '{ "to": "eosdactokens", "quantity": "1000.0000 ABY", "memo": "Initial amount of tokens for you."}'), allow_error: true
    its(:stderr) {is_expected.to include('Transaction should have at least one required authority')}
  end

  context "without owner auth should fail" do
    command %(cleos push action eosdactokens issue '{ "to": "tester1", "quantity": "1000.0000 ABY", "memo": "Initial amount of tokens for you."} -p tester1'), allow_error: true
    its(:stderr) {is_expected.to include('Transaction should have at least one required authority')}
  end

  context "with mismatching auth should fail" do
    command %(cleos push action eosdactokens issue '{ "to": "eosdactokens", "quantity": "1000.0000 ABY", "memo": "Initial amount of tokens for you."}' -p eosio), allow_error: true
    its(:stderr) {is_expected.to include('Error 3090004')}
  end

  context "with valid auth should succeed" do
    command %(cleos push action eosdactokens issue '{ "to": "eosdactokens", "quantity": "1000.0000 ABY", "memo": "Initial amount of tokens for you."}' -p eosdactokens), allow_error: true
    its(:stdout) {is_expected.to include('eosdactokens::issue')}
  end

  context "greater than max should fail" do
    command %(cleos push action eosdactokens issue '{ "to": "eosdactokens", "quantity": "11000.0000 ABY", "memo": "Initial amount of tokens for you."}' -p eosdactokens), allow_error: true
    its(:stderr) {is_expected.to include('Error 3050003')}
  end

  context "for inflation with valid auth should succeed" do
    command %(cleos push action eosdactokens issue '{ "to": "eosdactokens", "quantity": "2000.0000 ABY", "memo": "Initial amount of tokens for you."}' -p eosdactokens), allow_error: true
    its(:stdout) {is_expected.to include('eosdactokens::issue')}
  end
end

describe "Read back the stats after issuing currency should display max supply, supply and issuer" do
  command %(cleos get currency stats eosdactokens ABY), allow_error: true
  it do
    expect(JSON.parse(subject.stdout)).to eq JSON.parse <<~JSON
    {
      "ABY": {
        "supply": "3000.0000 ABY",
        "max_supply": "10000.0000 ABY",
        "issuer": "eosdactokens"
      }
    }
    JSON
  end
end

describe "Transfer some tokens" do
  context "without auth should fail" do
    command %(cleos push action eosdactokens transfer '{ "from": "eosdactokens", "to": "eosio", "quantity": "500.0000 ABY", "memo": "my first transfer"}'), allow_error: true
    its(:stderr) {is_expected.to include('Transaction should have at least one required authority')}
  end

  context "with mismatching auth should fail" do
    command %(cleos push action eosdactokens transfer '{ "from": "eosdactokens", "to": "eosio", "quantity": "500.0000 ABY", "memo": "my first transfer"}' -p eosio), allow_error: true
    its(:stderr) {is_expected.to include('Error 3090004')}
  end

  context "with valid auth should succeed" do
    command %(cleos push action eosdactokens transfer '{ "from": "eosdactokens", "to": "eosio", "quantity": "500.0000 ABY", "memo": "my first transfer"}' --permission eosdactokens@active), allow_error: true
    its(:stdout) {is_expected.to include('500.0000 ABY')}
  end

  context "with amount greater than balance should fail" do
    command %(cleos push action eosdactokens transfer '{ "from": "eosio", "to": "eosdactokens", "quantity": "50000.0000 ABY", "memo": "my first transfer"}' -p eosio), allow_error: true
    its(:stderr) {is_expected.to include('Error 3050003')}
  end
end

describe "Read back the result balance" do
  command %(cleos get currency balance eosdactokens eosdactokens), allow_error: true
  its(:stdout) {is_expected.to include('500.0000 ABY')}

end

describe "Unlock tokens" do
  context "without auth should fail" do
    command %(cleos push action eosdactokens unlock '{"unlock": "9500.0000 ABP"}'), allow_error: true
    its(:stderr) {is_expected.to include('Error 3040003')}
  end

  context "with auth should succeed" do
    before do
      puts `cleos push action eosdactokens create '{ "issuer": "eosdactokens", "maximum_supply": "10000.0000 ABX", "transfer_locked": true}' -p eosdactokens`
    end
    command %(cleos push action eosdactokens unlock '{"unlock": "9500.0000 ABX"}' -p eosdactokens), allow_error: true
    its(:stdout) {is_expected.to include('eosdactokens <= eosdactokens::unlock')}
  end
end

describe "Burn tokens" do
  context "before unlocking token should fail" do
    before do
      puts `cleos push action eosdactokens create '{ "issuer": "eosdactokens", "maximum_supply": "10000.0000 ABZ", "transfer_locked": true}' -p eosdactokens`
    end
    command %(cleos push action eosdactokens burn '{"from": "eosdactokens", "quantity": "9500.0000 ABZ"}' -p eosdactokens), allow_error: true
    its(:stderr) {is_expected.to include('Error 3050003')}
  end

  context "After unlocking token" do
    before(:all) do
      puts `cleos push action eosdactokens unlock '{"unlock": "9500.0000 ABP"}' -p eosdactokens`
    end

    context "more than available supply should fail" do
      before do
        puts `cleos push action eosdactokens transfer '{"from": "eosdactokens", "to": "testuser1", "quantity": "900.0000 ABP", "memo": "anything"}' -p eosdactokens`
      end
      command %(cleos push action eosdactokens burn '{"from": "testuser1", "quantity": "9600.0000 ABP"}' -p testuser1), allow_error: true
      its(:stderr) {is_expected.to include('Error 3050003')}
    end

    context "without auth should fail" do
      command %(cleos push action eosdactokens burn '{ "from": "eosdactokens","quantity": "500.0000 ABP"}'), allow_error: true
      its(:stderr) {is_expected.to include('Transaction should have at least one required authority')}
    end

    context "with wrong auth should fail" do
      command %(cleos push action eosdactokens burn '{"from": "eosdactokens", "quantity": "500.0000 ABP"}' -p eosio), allow_error: true
      its(:stderr) {is_expected.to include('Error 3090004')}
    end

    context "with legal amount of tokens should succeed" do
      command %(cleos push action eosdactokens burn '{"from": "testuser1", "quantity": "90.0000 ABP"}' -p testuser1), allow_error: true
      its(:stdout) {is_expected.to include('eosdactokens::burn')}
    end
  end
end

describe "Read back the stats after burning currency should display reduced supply, same max supply and issuer" do
  command %(cleos get currency stats eosdactokens ABP), allow_error: true
  it do
    expect(JSON.parse(subject.stdout)).to eq JSON.parse <<~JSON
      {
        "ABP": {
          "supply": "910.0000 ABP",
          "max_supply": "10000.0000 ABP",
          "issuer": "eosdactokens"
        }
      }
    JSON
  end
end

describe "newmemterms" do
  context "without valid auth" do
    command %(cleos push action eosdactokens newmemterms '{ "terms": "New Latest terms", "hash": "termshashsdsdsd"}' -p tester1), allow_error: true
    its(:stderr) {is_expected.to include('Ensure that you have the related private keys inside your wallet and your wallet is unlocked')}
  end

  context "without empty terms" do
    command %(cleos push action eosdactokens newmemterms '{ "terms": "", "hash": "termshashsdsdsd"}' -p eosdactokens), allow_error: true
    its(:stderr) {is_expected.to include('Error 3050003')}
  end

  context "with long terms" do
    command %(cleos push action eosdactokens newmemterms '{ "terms": "aasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdfasdfasdfasddasdf", "hash": "termshashsdsdsd"}' -p eosdactokens), allow_error: true
    its(:stderr) {is_expected.to include('Error 3050003')}
  end

  context "without empty hash" do
    command %(cleos push action eosdactokens newmemterms '{ "terms": "normallegalterms", "hash": ""}' -p eosdactokens), allow_error: true
    its(:stderr) {is_expected.to include('Error 3050003')}
  end

  context "with long hash" do
    command %(cleos push action eosdactokens newmemterms '{ "terms": "normallegalterms", "hash": "asdfasdfasdfasdfasdfasdfasdfasdfl"}' -p eosdactokens), allow_error: true
    its(:stderr) {is_expected.to include('Error 3050003')}
  end

  context "with valid terms and hash" do
    command %(cleos push action eosdactokens newmemterms '{ "terms": "normallegalterms", "hash": "asdfasdfasdfasdfasdfasd"}' -p eosdactokens), allow_error: true
    its(:stdout) {is_expected.to include('eosdactokens <= eosdactokens::newmemterms')}
  end

  context "for other dac" do
    context "with non matching auth" do
      command %(cleos push action eosdactokens newmemtermse '{ "terms": "otherlegalterms", "hash": "asdfasdfasdfasdfffffasd", "managing_account": "invalidacc"}' -p otherdacacc), allow_error: true
      its(:stderr) {is_expected.to include('missing authority of invalidacc')}
    end
    context "with matching auth" do
      command %(cleos push action eosdactokens newmemtermse '{ "terms": "otherlegalterms", "hash": "asdfasdfasdfasdfffffasd", "managing_account": "otherdacacc"}' -p otherdacacc), allow_error: true
      its(:stdout) {is_expected.to include('eosdactokens <= eosdactokens::newmemtermse')}
    end
  end
end
describe "Read back the memberterms for eosdactokens", focus: true do
  command %(cleos get table eosdactokens eosdactokens memberterms), allow_error: true
  it do
    expect(JSON.parse(subject.stdout)).to eq JSON.parse <<~JSON
      {
        "rows": [{
            "terms": "normallegalterms",
            "hash": "asdfasdfasdfasdfasdfasd",
            "version": 1
          }
        ],
        "more": false
      }
    JSON
  end
end
describe "Read back the memberterms for otherdacacc", focus: true do
  command %(cleos get table eosdactokens otherdacacc memberterms), allow_error: true
  it do
    expect(JSON.parse(subject.stdout)).to eq JSON.parse <<~JSON
      {
        "rows": [{
            "terms": "otherlegalterms",
            "hash": "asdfasdfasdfasdfffffasd",
            "version": 1
          }
        ],
        "more": false
      }
    JSON
  end
end

describe "updateterms" do
  context "without valid auth" do
    command %(cleos push action eosdactokens updateterms '{ "termsid": 1, "terms": "termshashsdsdsd"}' -p tester1), allow_error: true
    its(:stderr) {is_expected.to include('Ensure that you have the related private keys inside your wallet and your wallet is unlocked')}
  end

  context "with long terms" do
    command %(cleos push action eosdactokens updateterms '{ "termsid": 1, "terms": "lkhasdfkjhasdkfjhaksdljfhlkajhdflkhadfkahsdfkjhasdkfjhaskdfjhaskdhfkasjdhfkhasdfkhasdfkjhasdkfjhklasdflkhasdfkjhasdkfjhaksdljfhlkajhdflkhadfkahsdfkjhasdkfjhaskdfjhaskdhfkasjdhfkhasdfkhasdfkjhasdfkjhasdkfjhaksdljfhlkajhdflkhadfkahsdfkjhasdkfjhaskdfjhaskdhfkasjdhfkhasdfkhasdfkjhasdkfjhklasdf"}' -p eosdactokens), allow_error: true
    its(:stderr) {is_expected.to include('Error 3050003')}
  end

  context "with valid terms" do
    command %(cleos push action eosdactokens updateterms '{ "termsid": 1, "terms": "newtermslocation"}' -p eosdactokens), allow_error: true
    its(:stdout) {is_expected.to include('eosdactokens <= eosdactokens::updateterms')}
  end

  context "for other dac" do
    context "with non matching auth" do
      command %(cleos push action eosdactokens updatetermse '{ "termsid": 1, "terms": "asdfasdfasdfasdfffffasd", "managing_account": "invalidacc"}' -p otherdacacc), allow_error: true
      its(:stderr) {is_expected.to include('missing authority of invalidacc')}
    end
    context "with matching auth" do
      command %(cleos push action eosdactokens updatetermse '{ "termsid": 1, "terms": "otherdacterms", "managing_account": "otherdacacc"}' -p otherdacacc), allow_error: true
      its(:stdout) {is_expected.to include('eosdactokens <= eosdactokens::updatetermse')}
    end
  end
end
describe "Read back the memberterms for eosdactokens", focus: true do
  command %(cleos get table eosdactokens eosdactokens memberterms), allow_error: true
  it do
    expect(JSON.parse(subject.stdout)).to eq JSON.parse <<~JSON
      {
        "rows": [{
            "terms": "newtermslocation",
            "hash": "asdfasdfasdfasdfasdfasd",
            "version": 1
          }
        ],
        "more": false
      }
    JSON
  end
end
describe "Read back the memberterms for otherdacacc", focus: true do
  command %(cleos get table eosdactokens otherdacacc memberterms), allow_error: true
  it do
    expect(JSON.parse(subject.stdout)).to eq JSON.parse <<~JSON
      {
        "rows": [{
            "terms": "otherdacterms",
            "hash": "asdfasdfasdfasdfffffasd",
            "version": 1
          }
        ],
        "more": false
      }
    JSON
  end
end

describe "Member reg" do
  before(:all) do
    puts "before stuff"
  end

  context "without auth should fail" do
    command %(cleos push action eosdactokens memberreg '{ "sender": "eosio", "agreedterms": "New Latest terms"}'), allow_error: true
    its(:stderr) {is_expected.to include('Transaction should have at least one required authority')}
  end

  context "with mismatching auth should fail" do
    command %(cleos push action eosdactokens memberreg '{ "sender": "eosio", "agreedterms": "New Latest terms"}' -p eosdactokens), allow_error: true
    its(:stderr) {is_expected.to include('Error 3090004')}
  end

  context "with valid auth for second account should succeed" do
    command %(cleos push action eosdactokens memberreg '{ "sender": "testuser2", "agreedterms": "asdfasdfasdfasdfasdfasd"}' -p testuser2), allow_error: true
    its(:stdout) {is_expected.to include('eosdactokens::memberreg')}
  end
  context "for other dac" do
    context "with invalid managing_account should fail" do
      command %(cleos push action eosdactokens memberrege '{ "sender": "eosio", "agreedterms": "New Latest terms", "managing_account": "invalidacc"}' -p eosdactokens), allow_error: true
      its(:stderr) {is_expected.to include('Error 3090004')}
    end

    context "with valid managing account should succeed" do
      command %(cleos push action eosdactokens memberrege '{ "sender": "testuser1", "agreedterms": "asdfasdfasdfasdfffffasd", "managing_account": "otherdacacc"}' -p testuser1), allow_error: true
      its(:stdout) {is_expected.to include('eosdactokens::memberrege')}
    end
  end

  describe "Read back the result for regmembers in eosdactokens hasagreed should have one account", focus: true do
    command %(cleos get table eosdactokens eosdactokens members), allow_error: true
    it do
      expect(JSON.parse(subject.stdout)).to eq JSON.parse <<~JSON
      {
        "rows": [
          {"sender":"testuser2", "agreedtermsversion":1}
        ],
        "more": false
      }
      JSON
    end
  end
  describe "Read back the result for regmembers in eosdactokens hasagreed should have one account", focus: true do
    command %(cleos get table eosdactokens otherdacacc members), allow_error: true
    it do
      expect(JSON.parse(subject.stdout)).to eq JSON.parse <<~JSON
      {
        "rows": [
          {"sender":"testuser1", "agreedtermsversion":1}
        ],
        "more": false
      }
      JSON
    end
  end
end

describe "Update existing member reg" do
  before(:all) do
    puts `cleos push action eosdactokens newmemterms '{ "terms": "normallegalterms2", "hash": "dfghdfghdfghdfghdfg"}' -p eosdactokens`
  end

  context "without auth should fail" do
    command %(cleos push action eosdactokens memberreg '{ "sender": "tester3", "agreedterms": "subsequenttermsagreedbyuser"}'), allow_error: true
    its(:stderr) {is_expected.to include('Transaction should have at least one required authority')}
  end

  context "with mismatching auth should fail" do
    command %(cleos push action eosdactokens memberreg '{ "sender": "tester3", "agreedterms": "subsequenttermsagreedbyuser"}' -p eosdactokens), allow_error: true
    its(:stderr) {is_expected.to include('Error 3090004')}
  end

  context "with valid auth" do
    command %(cleos push action eosdactokens memberreg '{ "sender": "testuser3", "agreedterms": "dfghdfghdfghdfghdfg"}' -p testuser3@active), allow_error: true
    its(:stdout) {is_expected.to include('eosdactokens::memberreg')}
  end
  context "for other dac" do
    context "with invalid managing_account should fail" do
      command %(cleos push action eosdactokens memberrege '{ "sender": "testuser3", "agreedterms": "dfghdfghdfghdfghdfg", "managing_account": "invalidacc"}' -p eosdactokens), allow_error: true
      its(:stderr) {is_expected.to include('Error 3090004')}
    end

    context "with valid managing account should succeed" do
      command %(cleos push action eosdactokens memberrege '{ "sender": "testuser1", "agreedterms": "asdfasdfasdfasdfffffasd", "managing_account": "otherdacacc"}' -p testuser1), allow_error: true
      its(:stdout) {is_expected.to include('eosdactokens::memberrege')}
    end
  end
end

describe "Read back the result for regmembers on eosdactokens hasagreed should have entry" do
  command %(cleos get table eosdactokens eosdactokens members), allow_error: true
  it do
    expect(JSON.parse(subject.stdout)).to eq JSON.parse <<~JSON
    {
      "rows": [
        {"sender":"testuser2", "agreedtermsversion":1},
        {"sender":"testuser3", "agreedtermsversion":2}
      ],
      "more": false
    }
    JSON
  end
end
describe "Read back the result for regmembers hasagreed should have entry" do
  command %(cleos get table eosdactokens otherdacacc members), allow_error: true
  it do
    expect(JSON.parse(subject.stdout)).to eq JSON.parse <<~JSON
    {
      "rows": [
        {"sender":"testuser1", "agreedtermsversion":1}  
      ],
      "more": false
    }
    JSON
  end
end


describe "Unregister existing member" do
  context "without correct auth" do
    command %(cleos push action eosdactokens memberunreg '{ "sender": "testuser3"}'), allow_error: true
    its(:stderr) {is_expected.to include('Transaction should have at least one required authority')}
  end

  context "with mismatching auth" do
    command %(cleos push action eosdactokens memberunreg '{ "sender": "testuser3"}' -p currency@active), allow_error: true
    its(:stderr) {is_expected.to include('Error 3090003')}
  end

  context "with correct auth" do
    command %(cleos push action eosdactokens memberunreg '{ "sender": "testuser3"}' -p testuser3@active), allow_error: true
    its(:stdout) {is_expected.to include('eosdactokens::memberunreg')}
  end
  context "for other dac" do
    context "with invalid managing account" do
      command %(cleos push action eosdactokens memberunrege '{ "sender": "testuser1", "managing_account": "invalidacc"}' -p testuser1), allow_error: true
      its(:stderr) {is_expected.to include('managing_account is not valid')}
    end
    context "with correct auth" do
      command %(cleos push action eosdactokens memberunrege '{ "sender": "testuser1", "managing_account": "otherdacacc"}' -p testuser1), allow_error: true
      its(:stdout) {is_expected.to include('eosdactokens::memberunreg')}
    end
  end
end

describe "Read back the result for regmembers has agreed should be 0" do
  command %(cleos get table eosdactokens eosdactokens members), allow_error: true
  it do
    expect(JSON.parse(subject.stdout)).to eq JSON.parse <<-JSON
    {
      "rows": [
        {"sender":"testuser2", "agreedtermsversion":1}
    ],
    "more": false
  }
    JSON
  end
end
describe "Read back the result for regmembers has agreed should be 0" do
  command %(cleos get table eosdactokens otherdacacc members), allow_error: true
  it do
    expect(JSON.parse(subject.stdout)).to eq JSON.parse <<-JSON
    {
      "rows": [],
    "more": false
  }
    JSON
  end
end


describe "Adding contract to listen to transfers" do
  # Tests before this have already tested that transfer work before the notifyctr is set
  #
  context "Without valid auth should fail" do
    command %(cleos push action eosdactokens updateconfig '["eosdactokens"]' -p nontoken), allow_error: true
    its(:stderr) {is_expected.to include('Error 3090003: Provided keys, permissions, and delays do not satisfy declared authorizations')}
  end

  context "With invalid dest account should fail" do
    command %(cleos push action eosdactokens updateconfig '["noncontract"]' -p eosdactokens), allow_error: true
    its(:stderr) {is_expected.to include('Invalid contract attempt to be set for notifying')}
  end

  context "With valid dest account and auth should succeed" do
    command %(cleos push action eosdactokens updateconfig '["daccustodian"]' -p eosdactokens), allow_error: true
    its(:stdout) {is_expected.to include('eosdactokens::updateconfig   {"notifycontr":"daccustodian"}')}
  end

  context "Transfer should still succeed" do
    command %(cleos push action eosdactokens transfer '{ "from": "eosdactokens", "to": "eosio", "quantity": "498.0000 ABY", "memo": "my first transfer"}' --permission eosdactokens@active), allow_error: true
    its(:stdout) {is_expected.to include('498.0000 ABY')}
  end
end

