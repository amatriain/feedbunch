require 'rails_helper'

describe 'demo user', type: :feature do

  before :each do
    @demo_email = 'demo@feedbunch.com'
    Feedbunch::Application.config.demo_email = @demo_email

    @demo_password = 'feedbunch-demo'
    Feedbunch::Application.config.demo_password = @demo_password

    @demo_user = FactoryBot.create :user,
                                    email: @demo_email,
                                    password: @demo_password,
                                    confirmed_at: Time.zone.now
  end

  context 'demo disabled' do

    before :each do
      Feedbunch::Application.config.demo_enabled = false
    end

    it 'does not show a link to the demo', js: true do
      visit root_path
      expect(page).not_to have_css '#demo-link'
    end
  end

  context 'demo enabled' do

    before :each do
      Feedbunch::Application.config.demo_enabled = true
      visit root_path
    end

    it 'shows a link to the demo', js: true do
      expect(page).to have_css '#demo-link'
      within "#demo-link a" do
        expect(page).to have_content 'try a free demo'
      end
    end

    it 'shows an informative popup', js: true do
      find('#demo-link a').click
      expect(page).to have_css '#demo-info-popup', visible: true

      # popup should contain demo user credentials
      within '#demo-info-popup' do
        expect(page).to have_content Feedbunch::Application.config.demo_email
        expect(page).to have_content Feedbunch::Application.config.demo_password
      end
    end

    it 'cannot change demo user email', js: true do
      login_user_for_feature @demo_user
      visit edit_user_registration_path
      new_email = 'new_email@test.com'
      fill_in 'Email', with: new_email
      fill_in 'Current password', with: @demo_user.password
      click_on 'Update account'
      logout_user_for_feature

      mail_should_not_be_sent
      # test that demo user can login with the same email
      login_user_for_feature @demo_user
    end

    it 'cannot change demo user password', js: true do
      login_user_for_feature @demo_user
      visit edit_user_registration_path
      new_password = 'new_password'
      fill_in 'New password', with: new_password
      fill_in 'Password (again)', with: new_password
      fill_in 'Current password', with: @demo_user.password
      click_on 'Update account'
      logout_user_for_feature

      # test that demo user can login with the old password
      login_user_for_feature @demo_user
    end

    it 'demo user cannot be locked because of authentication failures', js: true do
      # user are normally locked after 5 failed authentication attempts
      wrong_password = 'wrong_password'
      (1..6).each do
        failed_login_user_for_feature @demo_user.email, wrong_password
      end

      # Check that user is not locked
      login_user_for_feature @demo_user
    end
  end

end