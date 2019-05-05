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

CONTRACT_NAME = 'eosdactokens'
ACCOUNT_NAME = 'eosdactokens'

RSpec.configure do |config|
  config.include RSpecCommand
end

beforescript = <<~SHELL
  set -x

  echo "asdfasdfasdfasdf"
  cleos wallet unlock --password `cat ~/eosio-wallet/.pass`

  cleos set contract #{CONTRACT_NAME} output/unit_tests/#{ACCOUNT_NAME} -p #{ACCOUNT_NAME}
  echo `pwd`

  echo "*************************"
  echo " This should run *AFTER* the daccustodian tests have run since it needs set up from that."
  echo "*************************"

SHELL

describe "eosdactokens" do
  before(:all) do
    `#{beforescript}`
    exit() unless $? == 0
  end

  describe "Unregister member that is active in candidates" do
    context "with wrong permission candidate" do
      command %(cleos push action eosdactokens memberunreg '{ "sender": "testuser3"}' -p currency@active), allow_error: true
      its(:stderr) {is_expected.to include('Error 3090003: Provided keys, permissions, and delays do not satisfy declared authorizations')}
    end

    context "with correct permission candidate" do
      context "is active candidate" do
        command %(cleos push action eosdactokens memberunreg '{ "sender": "votedcust3"}' -p votedcust3), allow_error: true
        its(:stderr) {is_expected.to include('ERR::MEMBERUNREG_ACTIVE_CANDIDATE::')}
      end

      context "inactive candidate" do
        command %(cleos push action eosdactokens memberunreg '{ "sender": "unreguser2"}' -p unreguser2), allow_error: true
        its(:stdout) {is_expected.to include('eosdactokens <= eosdactokens::memberunreg')}
      end

      context "inactive and unregistered candidate" do
        before(:all) { sleep 2.0 }
        command %(cleos push action eosdactokens memberunreg '{ "sender": "unreguser2"}' -p unreguser2), allow_error: true
        its(:stderr) {is_expected.to include('ERR::MEMBERUNREG_MEMBER_NOT_REGISTERED::')}
      end
    end
  end
end



