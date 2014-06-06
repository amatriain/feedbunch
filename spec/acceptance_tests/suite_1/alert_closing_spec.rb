require 'rails_helper'

describe 'automatically closing notices and alerts', type: :feature do
  before :each do
    @user = FactoryGirl.create :user
  end

  it 'closes rails notices after 5 seconds', js: true do
    login_user_for_feature @user
    page.should have_css 'div#notice'
    sleep 5
    page.should_not have_css 'div#notice'
  end

  it 'closes rails alerts after 5 seconds', js: true do
    visit new_user_session_path
    fill_in 'Email', with: @user.email
    fill_in 'Password', with: 'wrong password'
    click_on 'Sign in'

    page.should have_css 'div#alert'
    sleep 5
    page.should_not have_css 'div#alert'
  end

  it 'closes Devise errors after 5 seconds', js: true do
    visit new_user_registration_path
    fill_in 'Email', with: @user.email
    fill_in 'Password', with: 'password'
    fill_in 'Confirm password', with: 'different password'
    click_on 'Sign up'

    page.should have_css 'div#devise-error'
    sleep 5
    page.should_not have_css 'div#devise-error'
  end
end