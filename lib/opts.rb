require "date"
require "optparse"
require "optparse/date"
require_relative "api_key"

module Opts
  class Options < Struct.new(
    :api_key,
    :confirm,
    :internal_domain,
    keyword_init: true
  )
    def initialize(api_key: ApiKey.load_api_key, confirm: false, **kwargs)
      super
    end
  end

  def self.parse
    Options.new.tap do |options|
      OptionParser.new { |opts|
        opts.on("--api-key", "--access-token [ACCESS_TOKEN]", String, "PandaDoc API Key") do |api_key|
          ApiKey.store_api_key(api_key)
          options.api_key = api_key
        end

        opts.on("--internal-domain [DOMAIN_NAME]", String, "Internal Domain Name (e.g. 'example.com')") do |internal_domain|
          options.internal_domain = internal_domain
        end

        opts.on("--[no-]confirm", "Automatically confirm prompts") do |confirm|
          options.confirm = confirm
        end

        opts.on("-h", "--help", "Prints this help") do
          puts opts
          exit 0
        end
      }.parse!
    end
  end
end
