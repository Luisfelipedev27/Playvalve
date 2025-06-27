FactoryBot.define do
  factory :integrity_log do
    idfa { "MyString" }
    ban_status { "MyString" }
    ip { "MyString" }
    rooted_device { false }
    country { "MyString" }
    proxy { false }
    vpn { false }
  end
end
