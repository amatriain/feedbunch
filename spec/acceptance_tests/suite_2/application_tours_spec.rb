require 'rails_helper'

describe 'application tours', type: :feature do

  before :each do
    @user = FactoryGirl.create :user
  end

  context 'main application tour' do

    before :each do
      @user.update show_main_tour: true
      login_user_for_feature @user
    end

    it 'shows the tour', js: true do
      tour_should_be_visible 'Start'
    end

    it 'does not show the tour after completing it', js: true do
      tour_should_be_visible
      complete_tour

      visit read_path
      # wait for client code to initialize
      sleep 1
      tour_should_not_be_visible
    end

    it 'does not show the tour after closing it', js: true do
      tour_should_be_visible
      close_tour

      visit read_path
      # wait for client code to initialize
      sleep 1
      tour_should_not_be_visible
    end
  end

  context 'feed application tour' do

    before :each do
      @user.update show_feed_tour: true

      @feed1 = FactoryGirl.create :feed
      @feed2 = FactoryGirl.create :feed

      @entry1 = FactoryGirl.build :entry, feed_id: @feed1.id
      @feed1.entries << @entry1

      @entry2 = FactoryGirl.build :entry, feed_id: @feed2.id
      @feed2.entries << @entry2

      @user.subscribe @feed1.fetch_url
      @user.subscribe @feed2.fetch_url

      login_user_for_feature @user
    end

    it 'shows the tour when reading a feed', js: true do
      read_feed @feed1, @user
      tour_should_be_visible 'Entries list'
    end

    it 'does not show the tour after completing it', js: true do
      read_feed @feed1, @user
      tour_should_be_visible
      complete_tour

      # Click on a second feed without reloading the page
      read_feed @feed2, @user
      tour_should_not_be_visible

      # Reload the page and click on a feed
      visit read_path
      read_feed @feed1, @user
      # wait for client code to initialize
      sleep 1
      tour_should_not_be_visible
    end

    it 'does not show the tour after closing it', js: true do
      read_feed @feed1, @user
      tour_should_be_visible
      close_tour

      # Click on a second feed without reloading the page
      read_feed @feed2, @user
      tour_should_not_be_visible

      # Reload the page and click on a feed
      visit read_path
      read_feed @feed1, @user
      # wait for client code to initialize
      sleep 1
      tour_should_not_be_visible
    end
  end

  context 'entry application tour' do

    before :each do
      @user.update show_entry_tour: true

      @feed1 = FactoryGirl.create :feed

      @entry1 = FactoryGirl.build :entry, feed_id: @feed1.id
      @entry2 = FactoryGirl.build :entry, feed_id: @feed1.id
      @entry3 = FactoryGirl.build :entry, feed_id: @feed1.id
      @feed1.entries << @entry1 << @entry2 << @entry3

      @user.subscribe @feed1.fetch_url

      login_user_for_feature @user
    end

    it 'shows the tour when opening an entry', js: true do
      read_feed @feed1, @user
      open_entry @entry1
      tour_should_be_visible 'Entries'
    end

    it 'does not show the tour after completing it', js: true do
      read_feed @feed1, @user
      open_entry @entry1
      tour_should_be_visible
      complete_tour

      # Open a second entry without reloading the page
      open_entry @entry2
      tour_should_not_be_visible

      # Reload the page and click on a feed
      visit read_path
      read_feed @feed1, @user
      open_entry @entry3
      # wait for client code to initialize
      sleep 1
      tour_should_not_be_visible
    end

    it 'does not show the tour after closing it', js: true do
      read_feed @feed1, @user
      open_entry @entry1
      tour_should_be_visible
      close_tour

      # Open a second entry without reloading the page
      open_entry @entry2
      tour_should_not_be_visible

      # Reload the page and click on a feed
      visit read_path
      read_feed @feed1, @user
      open_entry @entry3
      # wait for client code to initialize
      sleep 1
      tour_should_not_be_visible
    end
  end

  context 'returning users' do

    before :each do
      @user.update show_main_tour: false,
                   show_feed_tour: false

      @feed1 = FactoryGirl.create :feed
      @entry1 = FactoryGirl.build :entry, feed_id: @feed1.id
      @feed1.entries << @entry1
      @user.subscribe @feed1.fetch_url

      login_user_for_feature @user
    end

    it 'does not show the main tour', js: true do
      tour_should_not_be_visible
    end

    it 'does not show the feed tour', js: true do
      read_feed @feed1, @user
      tour_should_not_be_visible
    end

    it 'does not show the entry tour', js: true do
      read_feed @feed1, @user
      open_entry @entry1
      tour_should_not_be_visible
    end

    context 'reset tours' do

      it 'shows alert after resetting tours'

      it 'shows an alert if an error is raised resetting tours'

      it 'shows main tour again'

      it 'shows feed tour again'

      it 'shows entry tour again'

    end

  end
end