require 'spec_helper'

describe 'authorization' do

  before :each do
    @normal_user = FactoryGirl.create :user
    @admin_user = FactoryGirl.create :user_admin
  end

  it 'shows Resque link to admin users' do
    login_user_for_feature @admin_user
    visit feeds_path

    page.should have_css 'a[href="/admin/resque"]'
  end

  it 'does not show Resque link to non-admin users' do
    login_user_for_feature @normal_user
    visit feeds_path

    page.should_not have_css 'a[href="/admin/resque"]'
  end

  it 'allows access to Resque to admin users' do
    login_user_for_feature @admin_user
    visit '/admin/resque'
    page.status_code.should eq 200
  end

  it 'does not allow access to Resque to non-admin users' do
    login_user_for_feature @normal_user
    expect {visit '/admin/resque'}.to raise_error ActionController::RoutingError
  end
end