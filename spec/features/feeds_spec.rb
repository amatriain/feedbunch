require 'spec_helper'

describe 'feeds' do
  it 'redirects unauthenticated visitors to logn page' do
    visit '/feeds'
    current_path.should eq '/users/sign_in'
  end
end