class ApplicationService
  attr_reader :error_message

  def self.call(**kwargs)
    new(**kwargs).call
  end

  def call
    self
  end

  def success?
    error_message.blank?
  end

  private

  attr_writer :error_message
end
