require 'spec_helper'

describe 'authentication' do
  before :each do
    @user = FactoryGirl.create :user
  end

  it 'shows a login link in the main page' do
    visit '/'
    page.should have_css 'a#sign_in[href*="/users/sign_in"]'
  end

  it 'shows a signup link in the main page' do
    visit '/'
    page.should have_css 'a#sign_up[href*="/users/sign_up"]'
  end

  it 'redirects user to feeds after a successful login' do
    visit '/users/sign_in'
    fill_in 'Email', with: @user.email
    fill_in 'Password', with: @user.password
    click_on 'Sign in'
    current_path.should eq '/feeds'
  end

  it 'stays on the login page after a failed login attempt' do
    visit '/users/sign_in'
    fill_in 'Email', with: @user.email
    fill_in 'Password', with: 'wrong password!!!'
    click_on 'Sign in'
    current_path.should eq '/users/sign_in'
  end

end