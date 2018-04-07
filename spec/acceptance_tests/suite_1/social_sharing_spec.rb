require 'rails_helper'

describe 'social sharing', type: :feature do

  before :each do
    @user = FactoryBot.create :user
    @feed = FactoryBot.create :feed
    @entry = FactoryBot.build :entry, feed_id: @feed.id
    @feed.entries << @entry
    @user.subscribe @feed.fetch_url

    login_user_for_feature @user
    read_feed @feed, @user
    read_entry @entry
    open_entry_share_dropdown @entry
  end

  it 'shows twitter share link', js: true do
    within "#entry-#{@entry.id}-summary .entry-toolbar", visible: true do
      expect(page).to have_css "a[target='_blank'][href='https://twitter.com/intent/tweet?url=#{@entry.url}&via=feedbunch&text=#{@entry.title}']"
    end
  end

  it 'shows google+ share link', js: true do
    within "#entry-#{@entry.id}-summary .entry-toolbar", visible: true do
      expect(page).to have_css "a[target='_blank'][ng-click='share_gplus_entry(entry)']"
    end
  end

end