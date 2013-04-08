require 'spec_helper'

describe 'authentication' do
  it 'shows a login link in the main page' do
    pending
    visit '/'
    page.should have_css 'a#sign_in[href*="/users/sign_in"]'
  end

  it 'shows a signup link in the main page'
end