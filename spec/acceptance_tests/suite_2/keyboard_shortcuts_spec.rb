require 'rails_helper'
require 'selenium/webdriver/common/keys'

describe 'keyboard shortcuts', type: :feature do

  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed

    @entry1 = FactoryGirl.build :entry, feed_id: @feed.id, published: Time.zone.parse('2000-10-10')
    @entry2 = FactoryGirl.build :entry, feed_id: @feed.id, published: Time.zone.parse('2000-01-01')
    @feed.entries << @entry1 << @entry2

    @user.subscribe @feed.fetch_url

    login_user_for_feature @user
  end

  context 'entries shortcuts' do

    before :each do
      read_feed @feed, @user
    end

    it 'highlights first entry by default', js: true do
      entry_should_be_highlighted @entry1
      entry_should_not_be_highlighted @entry2
    end

    it 'moves up and down the list', js: true do
      # first entry is highlighted
      entry_should_be_highlighted @entry1

      # Move down
      press_key 'j'

      entry_should_not_be_highlighted @entry1
      entry_should_be_highlighted @entry2

      # Move up
      press_key 'k'

      entry_should_be_highlighted @entry1
      entry_should_not_be_highlighted @entry2
    end

    it 'opens and closes entry', js: true do
      # first entry is highlighted and closed
      entry_should_be_highlighted @entry1
      entry_should_be_closed @entry1

      # open entry
      press_key Selenium::WebDriver::Keys::KEYS[:space]
      entry_should_be_open @entry1

      # close entry
      press_key Selenium::WebDriver::Keys::KEYS[:space]
      entry_should_be_closed @entry1
    end
  end
end