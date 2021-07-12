require "keyring"

module ApiKey
  def self.load_api_key
    Keyring.new.get_password("pandadoc", "api_key")
  end

  def self.valid?(api_key)
    /^[0-9a-f]{40}$/.match?(api_key)
  end

  def self.store_api_key(api_key)
    raise "Access Token '#{api_key}' does not appear to be valid" unless valid?(api_key)
    Keyring.new.delete_password("pandadoc", "api_key")
    Keyring.new.set_password("pandadoc", "api_key", api_key)
  end
end
