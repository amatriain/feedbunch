require 'rails_helper'

describe 'invite friend', type: :feature do

  before :each do
    @user = FactoryGirl.create :user
    @friend_email = 'some_friends_email@domain.com'

    login_user_for_feature @user
    visit edit_user_registration_path
  end

  context 'send invitation' do

  end

  context 'accept invitation' do

  end

end