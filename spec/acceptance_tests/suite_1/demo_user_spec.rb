require 'rails_helper'

describe 'demo user', type: :feature do

  context 'demo disabled' do

    before :each do
      Feedbunch::Application.config.demo_enabled = false
      visit root_path
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

    # TODO: implement acceptance tests

    it 'cannot change his email'

    it 'cannot change his password'

    it 'cannot be locked because of authentication failures'
  end

end