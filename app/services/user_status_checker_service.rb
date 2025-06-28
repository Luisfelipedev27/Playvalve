class UserStatusCheckerService < ApplicationService
  COUNTRY_WHITELIST_KEY = 'country_whitelist'.freeze

  attr_reader :final_status_result

  def initialize(user_params:, ip:, country:)
    self.idfa = user_params[:idfa]
    self.rooted_device = user_params[:rooted_device]
    self.ip = ip
    self.country = country
    self.vpn_data = nil
    self.security_check_result = nil
  end

  def call
    find_or_create_user && fetch_vpn_data && final_status

    self
  end

  attr_accessor :idfa, :rooted_device, :ip, :country, :vpn_data, :user, :security_check_result

  attr_writer :final_status_result

  private

  def find_or_create_user
    if idfa.blank? || ip.blank?

      self.error_message = "IDFA and IP are required"
      return false
    end

    self.user = User.find_or_create_by(idfa: idfa) { |u| u.ban_status = 'not_banned' }

    return true if user.persisted?

    false
  end

  def fetch_vpn_data
    vpn_service = VpnApiClientService.call(ip: ip)

    self.vpn_data = vpn_service.result

    true
  end

  def final_status
    return set_result('banned') if user.ban_status == 'banned'

    ban_status = perform_security_checks

    user.update!(ban_status: ban_status) && create_integrity_log(ban_status)

    set_result(ban_status)

    true
  rescue ActiveRecord::RecordInvalid => e
    self.error_message = "Error updating user or creating log: #{e.message}"

    false
  end

  def perform_security_checks
    return security_check_result if security_check_result

    return ban_user unless country_whitelisted?
    return ban_user if rooted_device == true
    return ban_user if vpn_data[:vpn] || vpn_data[:proxy] || vpn_data[:tor] || vpn_data[:relay]

    allow_user
  end

  def country_whitelisted?
    return true if country.blank?

    Rails.cache.redis.with { |redis| redis.sismember(COUNTRY_WHITELIST_KEY, country) }
  end

  def ban_user
    self.security_check_result = 'banned'
  end

  def allow_user
    self.security_check_result = 'not_banned'
  end

  def set_result(status)
    self.final_status_result = status

    true
  end

  def create_integrity_log(ban_status)
    log_data = {
      idfa: idfa,
      ban_status: ban_status,
      ip: ip,
      rooted_device: rooted_device || false,
      country: country,
      proxy: vpn_data[:proxy] || false,
      vpn: vpn_data[:vpn] || vpn_data[:tor] || vpn_data[:relay] || false
    }

    logger_service = IntegrityLoggerService.call(log_data: log_data)

    return true if logger_service.success?

    self.error_message = "Integrity logging failed: #{logger_service.error_message}"

    false
  end
end
