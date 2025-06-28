require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:idfa) }
    it { should validate_uniqueness_of(:idfa) }
    it { should validate_presence_of(:ban_status) }
    it { should validate_inclusion_of(:ban_status).in_array(%w[banned not_banned]) }
  end

  describe 'associations' do
    it { should have_many(:integrity_logs).with_primary_key(:idfa).with_foreign_key(:idfa).dependent(:destroy) }
  end
end
