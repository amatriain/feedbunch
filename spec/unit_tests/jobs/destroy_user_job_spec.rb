require 'rails_helper'

describe DestroyUserJob do

  before :each do
    @user = FactoryGirl.create :user
  end

  it 'destroys user' do
    expect(User.exists?(@user.id)).to be true
    DestroyUserJob.perform @user.id
    expect(User.exists?(@user.id)).to be false
  end

  context 'validations' do

    it 'does nothing if the user does not exist' do
      expect_any_instance_of(User).not_to receive :destroy!
      expect_any_instance_of(User).not_to receive :destroy
      DestroyUserJob.perform 1234567890
    end

  end
end