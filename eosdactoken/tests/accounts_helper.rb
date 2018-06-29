
# Generate a sequential list of account names for testing.
# The account list will return the same list each time it's called to assist in repeatability.
#
# == Parameters:
# num::
#   The number of account names to generate.
#
# == Returns:
#     An array of strings that are valid to use as Eos.io account names.
def generate_account_names(num)
  charmap = ".12345abcdefghijklmnopqrstuvwxyz";

  value = 10 ** 18
  accounts = []

  num.times do |acc|
    value += 1
    str = ""
    tmp = value
    12.times do |idx|
      c = charmap[tmp & (idx == 0 ? 0x0f : 0x1f)]
      str[idx] = c
      tmp >>= (idx == 0 ? 4 : 5)
      str
    end
    accounts << str
  end
  accounts
end

# Creates accounts on a local chain using `cleos` using the a deterministic list of account names based on `generate_account_names`.
#
# == Parameters:
# num::
#   The number of accounts generate.
#
def create_accounts(num)
  ownerPrivatekey = "5JioEXzAEm7yXwu6NMp3meB1P4s4im2XX3ZcC1EC5LwHXo69xYS"
  ownerPublickey = "EOS7FuoE7h4Ruk3RkWXxNXAvhBnp7KSkq3g2NpYnLJpvtdPpXK3v8"
  activePrivatekey = "5JHo6cvEc78EGGcEiMMfNDiTfmeEbUFvcLEnvD8EYvwzcu8XFuW"
  activePublickey = "EOS4xowXCvVTzGLr5rgGufqCrhnj7yGxsHfoMUVD4eRChXRsZzu3S"
  puts `cleos wallet import #{ownerPrivatekey}`
  puts `cleos wallet import #{activePrivatekey}`

  accounts = generate_account_names num
  accounts.each do |acc|
    puts `cleos create account eosio #{acc} #{ownerPublickey} #{activePublickey}`
  end
  puts `cleos create account eosio testuser1 #{ownerPublickey} #{activePublickey}`
end

# create_accounts(1000)
# exit 0

def add_accounts_as_members(num)

  accounts = generate_account_names(num)
  params = accounts.each_with_index.map { |acc, i| %(["#{acc}", "0.0001 ABC"]) }.join(', ')

  puts `cleos push action eosdactoken memberadda '{"newmembers":[#{params}], "memo":"air drop balance"}' -p eosdactoken`
end
# create_accounts(30) # Need to only run this line once.
# add_accounts_as_members(30) # The most I could add in one transaction locally was around 250.