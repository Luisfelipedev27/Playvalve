class IntegrityLog < ApplicationRecord
  validates :idfa, presence: true
  validates :ban_status, presence: true, inclusion: { in: User::BAN_STATUSES }
  validates :ip, presence: true
end
