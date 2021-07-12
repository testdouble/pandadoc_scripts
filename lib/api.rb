require "net/http"
require "cgi"
require "json"
require_relative "cli"

module Api
  PAGE_SIZE = 100
  ENDPOINT = "https://api.pandadoc.com/public/v1/"

  def self.query_string(options)
    return "" if options.nil? || options.empty?
    "?" + options.map { |(k, v)| "#{k}=#{CGI.escape(v.to_s)}" }.join("&")
  end

  def self.get(api_key:, path:, options:, data_key: path, offset: 0)
    uri = URI(ENDPOINT + path + query_string(options.merge({page: 1 + (offset / PAGE_SIZE), count: PAGE_SIZE})))
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      req = Net::HTTP::Get.new(uri.request_uri)
      req["Authorization"] = "API-Key #{api_key}"
      response = http.request(req)
      json = JSON.parse(response.body)
      if (wait_seconds = throttled?(response))
        Cli.out "API request throttled, waiting #{wait_seconds} seconds"
        sleep wait_seconds
        get(
          api_key: api_key,
          path: path,
          options: options,
          data_key: data_key,
          offset: offset
        )
      else
        raise_api_error_maybe(response)
        results = data_key ? json[data_key] : json
        if results.length > 0 && results.size == PAGE_SIZE
          results += get(
            api_key: api_key,
            path: path,
            options: options,
            data_key: data_key,
            offset: offset + results.size
          )
        end
        return results
      end
    end
  end

  def self.post(api_key:, path:, body:)
    uri = URI(ENDPOINT + path)
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      req = Net::HTTP::Post.new(uri.request_uri)
      req["Authorization"] = "API-Key #{api_key}"
      req["Content-Type"] = "application/json"
      req.set_form_data(body)
      response = http.request(req)
      json = JSON.parse(response.body)
      raise_api_error_maybe(response)
      json
    end
  end

  def self.raise_api_error_maybe(response)
    return if response.code.start_with?("2")
    json = JSON.parse(response.body)
    raise "API request failed: #{response.code} - #{json["type"]} - #{json["detail"]}"
  end

  def self.throttled?(response)
    return unless response.code == "429"
    begin
      # Sometimes the JSON response will tell you how many seconds to wait,
      # otherwise the safe bet is to wait a minute
      JSON.parse(response.body)["detail"].match(/(\d+) seconds/)[1].to_i + 1
    rescue
      61
    end
  end
end
