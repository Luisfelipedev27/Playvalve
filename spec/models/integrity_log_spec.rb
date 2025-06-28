require 'rails_helper'

RSpec.describe IntegrityLog, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:idfa) }
    it { should validate_presence_of(:ban_status) }
    it { should validate_presence_of(:ip) }
    it { should validate_inclusion_of(:ban_status).in_array(%w[banned not_banned]) }
  end
end
