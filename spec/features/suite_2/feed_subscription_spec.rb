require 'spec_helper'

describe 'subscription to feeds' do

  before :each do
    @user = FactoryGirl.create :user
    @feed1 = FactoryGirl.create :feed
    @feed2 = FactoryGirl.create :feed

    @entry1 = FactoryGirl.build :entry, feed_id: @feed1.id
    @feed1.entries << @entry1
    @entry2 = FactoryGirl.build :entry, feed_id: @feed2.id
    @feed2.entries << @entry2

    @user.subscribe @feed1.fetch_url

    login_user_for_feature @user
    visit read_path
  end

  it 'shows feeds the user is subscribed to', js: true do
    page.should have_content @feed1.title
  end

  it 'does not show feeds the user is not subscribed to' do
    page.should_not have_content @feed2.title
  end

  
end
