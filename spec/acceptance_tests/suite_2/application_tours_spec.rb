require 'rails_helper'

describe 'application tours', type: :feature do

  before :each do
    @user = FactoryBot.create :user
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

      @feed1 = FactoryBot.create :feed
      @feed2 = FactoryBot.create :feed

      @entry1 = FactoryBot.build :entry, feed_id: @feed1.id
      @feed1.entries << @entry1

      @entry2 = FactoryBot.build :entry, feed_id: @feed2.id
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

      @feed1 = FactoryBot.create :feed

      @entry1 = FactoryBot.build :entry, feed_id: @feed1.id
      @entry2 = FactoryBot.build :entry, feed_id: @feed1.id
      @entry3 = FactoryBot.build :entry, feed_id: @feed1.id
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

  context 'keyboard shortcuts tour' do

    it 'shows the tour after completing main tour', js: true do
      @user.update show_main_tour: true,
                   show_kb_shortcuts_tour: true
      login_user_for_feature @user

      tour_should_be_visible 'Start'
      close_tour
      tour_should_be_visible 'Keyboard shortcuts'
    end

    it 'shows the tour if main tour was already finished', js: true do
      @user.update show_main_tour: false,
                   show_kb_shortcuts_tour: true
      login_user_for_feature @user
      tour_should_be_visible 'Keyboard shortcuts'
    end

    it 'does not show the tour after completing it', js: true do
      @user.update show_main_tour: false,
                   show_kb_shortcuts_tour: true
      login_user_for_feature @user
      complete_tour

      visit read_path
      # wait for client code to initialize
      sleep 1
      tour_should_not_be_visible
    end

    it 'does not show the tour after closing it', js: true do
      @user.update show_main_tour: false,
                   show_kb_shortcuts_tour: true
      login_user_for_feature @user
      close_tour

      visit read_path
      # wait for client code to initialize
      sleep 1
      tour_should_not_be_visible
    end
  end

  context 'returning users' do

    before :each do
      @user.update show_main_tour: false,
                   show_feed_tour: false,
                   show_entry_tour: false,
                   show_kb_shortcuts_tour: false

      @feed1 = FactoryBot.create :feed
      @entry1 = FactoryBot.build :entry, feed_id: @feed1.id
      @feed1.entries << @entry1
      @user.subscribe @feed1.fetch_url

      login_user_for_feature @user
    end

    it 'does not show the main or keyboard shortcuts tour', js: true do
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

      it 'shows alert after resetting tours', js: true do
        visit edit_user_registration_path
        find('#reset-tours-button').click
        should_show_alert 'success-reset-tours'
      end

      it 'shows an alert if an error is raised resetting tours', js: true do
        allow_any_instance_of(User).to receive(:update_config).and_raise StandardError.new

        visit edit_user_registration_path
        find('#reset-tours-button').click
        should_show_alert 'problem-show-tour-change'
      end

      it 'shows all tours again', js: true do
        reset_tours
        visit read_path

        # Show main tour
        tour_should_be_visible 'Start'
        close_tour

        # Show keyboard shortcuts tour
        tour_should_be_visible 'Keyboard shortcuts'
        close_tour


        # Show feed tour
        read_feed @feed1, @user
        tour_should_be_visible 'Entries list'
        close_tour

        # Show entry tour
        open_entry @entry1
        tour_should_be_visible 'Entries'
      end

    end

  end
end