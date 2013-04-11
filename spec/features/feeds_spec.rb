require 'spec_helper'

describe 'feeds' do
  it 'redirects unauthenticated visitors to login page' do
    visit feeds_path
    current_path.should eq new_user_session_path
  end
end