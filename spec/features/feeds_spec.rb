require 'spec_helper'

describe 'feeds' do
  before :each do
    # Ensure no actual HTTP calls are made
    RestClient.stub get: true
  end

  it 'redirects unauthenticated visitors to login page' do
    visit feeds_path
    current_path.should eq new_user_session_path
  end
end