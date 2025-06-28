class VpnApiClientService < ApplicationService
  ENDPOINT = 'https://vpnapi.io/api/'.freeze
  CACHE_EXPIRY = 24.hours.to_i

  attr_reader :result

  def initialize(ip:)
    self.ip = ip
    self.cache_key = "vpnapi:#{ip}"
    self.response = nil
  end

  def call
    check_cache && vpn_api_request && parse_and_cache_response

    self
  end

  attr_accessor :ip, :cache_key, :response

  attr_writer :result

  private

  def check_cache
    cached_data = Rails.cache.read(cache_key)
    if cached_data
      self.result = cached_data
      return false
    end

    true
  end

  def vpn_api_request
    connection = Faraday.new do |conn|
      conn.options.timeout = 10
      conn.options.open_timeout = 10
      conn.headers['User-Agent'] = 'PlayvalveChecker/1.0'
      conn.response :json, content_type: /\bjson$/
      conn.adapter Faraday.default_adapter
    end

    self.response = connection.get("#{ENDPOINT}#{ip}")

    if response.success?
      true
    else
      set_fallback_result
      false
    end

  rescue Faraday::TimeoutError, StandardError  => e
    Rails.logger.error "Error calling VPNAPI for IP #{ip}: #{e.message}"

    set_fallback_result

    false
  end

  def parse_and_cache_response
    parsed_data = parse_response_body

    Rails.cache.write(cache_key, parsed_data, expires_in: CACHE_EXPIRY)

    self.result = parsed_data

    true
  rescue StandardError => e
    Rails.logger.error "Error parsing VPNAPI response for #{ip}: #{e.message}"

    set_fallback_result

    false
  end

  def parse_response_body
    data = response.body.is_a?(Hash) ? response.body : JSON.parse(response.body)

    {
      proxy: data.dig('security', 'proxy') || false,
      vpn: data.dig('security', 'vpn') || data.dig('security', 'tor') || false
    }
  end

  def set_fallback_result
    self.result = {
      proxy: false,
      vpn: false
    }
  end
end
