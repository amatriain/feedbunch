require 'rails_helper'

describe 'demo user', type: :feature do

  context 'demo disabled' do

    before :each do
      Feedbunch::Application.config.demo_enabled = false
    end

    it 'does not show a link to the demo', js: true do
      visit root_path
    end
  end

  context 'demo enabled' do

    before :each do
      Feedbunch::Application.config.demo_enabled = true
    end

    it 'shows a link to the demo', js: true do
      visit root_path
    end

    it 'cannot change his email'

    it 'cannot change his password'

    it 'cannot be locked because of authentication failures'
  end

  # TODO: implement acceptance tests
end