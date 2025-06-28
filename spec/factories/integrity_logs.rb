FactoryBot.define do
  factory :integrity_log do
    idfa { SecureRandom.uuid }
    ban_status { 'not_banned' }
    ip { '192.168.1.1' }
    rooted_device { false }
    country { 'US' }
    proxy { false }
    vpn { false }
  end
end
