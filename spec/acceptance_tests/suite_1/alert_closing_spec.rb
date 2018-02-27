require 'rails_helper'

describe 'automatically closing notices and alerts', type: :feature do
  before :each do
    @user = FactoryBot.create :user
  end

  it 'closes rails notices after 5 seconds', js: true do
    login_user_for_feature @user
    expect(page).to have_css 'div#notice'
    sleep 5
    expect(page).to have_no_css 'div#notice'
  end

  it 'closes rails alerts after 5 seconds', js: true do
    visit new_user_session_path
    close_cookies_alert
    fill_in 'Email', with: @user.email
    fill_in 'Password', with: 'wrong password'
    click_on 'Log in'

    expect(page).to have_css 'div#alert'
    sleep 5
    expect(page).to have_no_css 'div#alert'
  end

  it 'closes Devise errors after 5 seconds', js: true do
    visit new_user_registration_path
    close_cookies_alert
    fill_in 'Email', with: @user.email
    fill_in 'Password', with: 'password'
    fill_in 'Password (again)', with: 'different password'
    click_on 'Sign up'

    expect(page).to have_css 'div#devise-error'
    sleep 5
    expect(page).to have_no_css 'div#devise-error'
  end
end