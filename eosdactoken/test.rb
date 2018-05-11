require 'rspec_command'
require 'json'

RSpec.configure do |config|
  config.include RSpecCommand
end

CONTRACT_NAME = 'eosdactoken'
ACCOUNT_NAME = 'eosdactoken'
TOKEN = 'EDF'

describe 'create new currency' do
  body = { issuer: ACCOUNT_NAME, maximum_supply: "10000.0000 #{TOKEN}", can_freeze: 0, can_recall: 0, can_whitelist: 0}
  command """
  cleos push action #{CONTRACT_NAME} create '#{ body.to_json }' -p #{ACCOUNT_NAME}
  """
  its(:stdout) { is_expected.to include('executed transaction') }
#   its(:exitstatus) { is_expected.to eq 0 }
end
