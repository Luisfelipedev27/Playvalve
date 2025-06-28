FactoryBot.define do
  factory :user do
    idfa { SecureRandom.uuid }
    ban_status { 'not_banned' }

    trait :banned do
      ban_status { 'banned' }
    end
  end
end
