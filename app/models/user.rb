class User < ApplicationRecord
  BAN_STATUSES = %w[banned not_banned].freeze

  validates :idfa, presence: true, uniqueness: true
  validates :ban_status, presence: true, inclusion: { in: BAN_STATUSES }

  has_many :integrity_logs, primary_key: :idfa, foreign_key: :idfa, dependent: :destroy
end
