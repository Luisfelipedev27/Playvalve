class IntegrityLoggerService < ApplicationService
  def initialize(log_data:)
    self.log_data = log_data
  end

  def call
    log_to_database && log_to_additional_sources

    self
  end

  attr_accessor :log_data

  private

  def log_to_database
    IntegrityLog.create!(log_data)

    true
  rescue StandardError => e
    self.error_message = "Database logging failed: #{e.message}"

    false
  end

  def log_to_additional_sources
    # Future: Add other data sources here
    # log_to_external_api if Rails.env.production?
    # log_to_analytics_service
    true
  end
end
