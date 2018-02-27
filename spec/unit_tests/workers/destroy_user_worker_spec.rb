require 'rails_helper'

describe DestroyUserWorker do

  before :each do
    @user = FactoryBot.create :user
  end

  it 'destroys user' do
    expect(User.exists?(@user.id)).to be true
    DestroyUserWorker.new.perform @user.id
    expect(User.exists?(@user.id)).to be false
  end

  context 'validations' do

    it 'does nothing if the user does not exist' do
      expect_any_instance_of(User).not_to receive :destroy!
      expect_any_instance_of(User).not_to receive :destroy
      DestroyUserWorker.new.perform 1234567890
    end

  end
end