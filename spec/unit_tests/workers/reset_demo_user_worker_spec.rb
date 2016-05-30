require 'rails_helper'

describe ResetDemoUserWorker do

  before :each do
    @demo_email = Feedbunch::Application.config.demo_email
    @demo_password = Feedbunch::Application.config.demo_password
  end

  context 'demo user disabled' do

    before :each do
      Feedbunch::Application.config.demo_enabled = false
    end

    it 'does not create demo user' do
      expect(User.find_by_email @demo_email).to be nil
      ResetDemoUserWorker.new.perform
      expect(User.find_by_email @demo_email).to be nil
    end

    it 'destroys demo user if it exists' do
      demo_user = FactoryGirl.create :user, email: @demo_email, password: @demo_password

      expect(User.find_by_email @demo_email).not_to be nil
      ResetDemoUserWorker.new.perform
      expect(User.find_by_email @demo_email).to be nil
    end
  end

  context 'demo user enabled' do

    before :each do
      Feedbunch::Application.config.demo_enabled = true

      allow_any_instance_of(User).to receive :subscribe do |user, url|
        if Feed.exists? fetch_url: url
          feed = Feed.find_by fetch_url: url
        else
          feed = FactoryGirl.create :feed, fetch_url: url
        end
        subscription = FactoryGirl.build :feed_subscription,
                                         user_id: user.id,
                                         feed_id: feed.id
        user.feed_subscriptions << subscription
        feed
      end
    end

    it 'creates demo user if it does not exist' do
      expect(User.find_by_email @demo_email).to be nil
      ResetDemoUserWorker.new.perform
      expect(User.find_by_email @demo_email).not_to be nil
    end

    it 'does not alter demo user if it exists' do
      demo_user = FactoryGirl.create :user, email: @demo_email, password: @demo_password

      expect(User.find_by_email @demo_email).not_to be nil
      ResetDemoUserWorker.new.perform
      expect(User.find_by_email @demo_email).to eq demo_user
    end

    context 'reset demo user' do

      before :each do
        @demo_user = FactoryGirl.create :user, email: @demo_email, password: @demo_password
      end

      it 'resets admin to false' do
        @demo_user.update admin: true

        expect(@demo_user.admin).to be true
        ResetDemoUserWorker.new.perform
        expect(@demo_user.reload.admin).to be false
      end

      it 'resets locale to default' do
        default_locale = I18n.default_locale
        @demo_user.update locale: :es

        expect(@demo_user.locale).to eq :es.to_s
        ResetDemoUserWorker.new.perform
        expect(@demo_user.reload.locale).to eq default_locale.to_s
      end

      it 'resets timezone to default' do
        default_time_zone = Feedbunch::Application.config.time_zone
        last_time_zone = ActiveSupport::TimeZone.all.last.name
        expect(default_time_zone).not_to eq last_time_zone
        @demo_user.update timezone: last_time_zone

        expect(@demo_user.timezone).to eq last_time_zone
        ResetDemoUserWorker.new.perform
        expect(@demo_user.reload.timezone).to eq default_time_zone
      end

      it 'resets quick_reading to default' do
        default_quick_reading = Feedbunch::Application.config.demo_quick_reading
        @demo_user.update quick_reading: !default_quick_reading

        expect(@demo_user.quick_reading).to be !default_quick_reading
        ResetDemoUserWorker.new.perform
        expect(@demo_user.reload.quick_reading).to be default_quick_reading
      end

      it 'resets open_all_entries to default' do
        default_open_all_entries = Feedbunch::Application.config.demo_open_all_entries
        @demo_user.update open_all_entries: !default_open_all_entries

        expect(@demo_user.open_all_entries).to be !default_open_all_entries
        ResetDemoUserWorker.new.perform
        expect(@demo_user.reload.open_all_entries).to be default_open_all_entries
      end

      it 'resets name to default' do
        default_name = Feedbunch::Application.config.demo_name
        another_name = 'another username'
        expect(default_name).not_to eq another_name
        @demo_user.update name: another_name

        expect(@demo_user.name).to eq another_name
        ResetDemoUserWorker.new.perform
        expect(@demo_user.reload.name).to eq default_name
      end

      it 'resets invitation limit to zero' do
        @demo_user.update invitation_limit: 1000

        expect(@demo_user.invitation_limit).not_to eq 0
        ResetDemoUserWorker.new.perform
        expect(@demo_user.reload.invitation_limit).to eq 0
      end

      it 'resets all tours' do
        @demo_user.update show_main_tour: false,
                          show_mobile_tour: false,
                          show_feed_tour: false,
                          show_entry_tour: false,
                          show_kb_shortcuts_tour: false

        expect(@demo_user.show_main_tour).to be false
        expect(@demo_user.show_mobile_tour).to be false
        expect(@demo_user.show_feed_tour).to be false
        expect(@demo_user.show_entry_tour).to be false
        ResetDemoUserWorker.new.perform
        expect(@demo_user.reload.show_main_tour).to be true
        expect(@demo_user.show_mobile_tour).to be true
        expect(@demo_user.show_feed_tour).to be true
        expect(@demo_user.show_entry_tour).to be true
        expect(@demo_user.show_kb_shortcuts_tour).to be true
      end

      it 'resets free to true' do
        @demo_user.update free: false

        expect(@demo_user.free).not_to be true
        ResetDemoUserWorker.new.perform
        expect(@demo_user.reload.free).to be true
      end

      it 'resets OPML import state to NONE' do
        opml_import = FactoryGirl.build :opml_import_job_state,
                                        user_id: @demo_user.id,
                                        state: OpmlImportJobState::SUCCESS,
                                        total_feeds: 10,
                                        processed_feeds: 10
        @demo_user.opml_import_job_state = opml_import

        expect(@demo_user.opml_import_job_state.state).not_to eq OpmlImportJobState::NONE
        ResetDemoUserWorker.new.perform
        expect(@demo_user.reload.opml_import_job_state.state).to eq OpmlImportJobState::NONE
      end

      it 'resets OPML export state to NONE' do
        opml_export = FactoryGirl.build :opml_export_job_state,
                                        user_id: @demo_user.id,
                                        state: OpmlExportJobState::ERROR
        @demo_user.opml_export_job_state = opml_export

        expect(@demo_user.opml_export_job_state.state).not_to eq OpmlExportJobState::NONE
        ResetDemoUserWorker.new.perform
        expect(@demo_user.reload.opml_export_job_state.state).to eq OpmlExportJobState::NONE
      end

      it 'destroys subscribe job states' do
        job_state_1 = FactoryGirl.build :subscribe_job_state,
                                        user_id: @demo_user.id,
                                        state: SubscribeJobState::SUCCESS
        job_state_2 = FactoryGirl.build :subscribe_job_state,
                                        user_id: @demo_user.id,
                                        state: SubscribeJobState::SUCCESS
        @demo_user.subscribe_job_states << job_state_1 << job_state_2

        expect(@demo_user.subscribe_job_states).not_to be_blank
        ResetDemoUserWorker.new.perform
        expect(@demo_user.reload.subscribe_job_states).to be_blank
      end

      it 'destroys refresh job states' do
        job_state_1 = FactoryGirl.build :refresh_feed_job_state,
                                        user_id: @demo_user.id,
                                        state: RefreshFeedJobState::SUCCESS
        job_state_2 = FactoryGirl.build :refresh_feed_job_state,
                                        user_id: @demo_user.id,
                                        state: RefreshFeedJobState::SUCCESS
        @demo_user.refresh_feed_job_states << job_state_1 << job_state_2

        expect(@demo_user.refresh_feed_job_states).not_to be_blank
        ResetDemoUserWorker.new.perform
        expect(@demo_user.reload.refresh_feed_job_states).to be_blank
      end

      context 'reset feeds and folders' do

        it 'resets folders' do
          folder_1 = FactoryGirl.build :folder, user_id: @demo_user.id
          folder_2 = FactoryGirl.build :folder, user_id: @demo_user.id
          @demo_user.folders << folder_1 << folder_2
          # remove the special value "NONE" from the list of default folders, it is not an actual folder
          # present for any user
          default_folders = Feedbunch::Application.config.demo_subscriptions.keys
          default_folders.delete Folder::NO_FOLDER

          expect(@demo_user.folders.map{ |f| f.title}).not_to match_array default_folders
          ResetDemoUserWorker.new.perform
          expect(@demo_user.reload.folders.map{ |f| f.title}).to match_array default_folders
        end

        it 'resets feeds' do
          default_subscriptions = Feedbunch::Application.config.demo_subscriptions

          # One of the default demo feeds exists but the demo user is not subscribed to it
          demo_feed_url = default_subscriptions.values.flatten.first
          demo_feed = FactoryGirl.create :feed, fetch_url: demo_feed_url

          # The user is subscribed to two feeds not in defaults
          feed_1 = @demo_user.subscribe 'http://some.feed.com'
          feed_2 = @demo_user.subscribe 'http://another.feed.com'

          # Add an empty array of feeds in "NO_FOLDER" unless there are already feeds in "NO_FOLDER" in the
          # default subscriptions
          default_subscriptions[Folder::NO_FOLDER] = [] unless default_subscriptions.keys.include? Folder::NO_FOLDER

          ResetDemoUserWorker.new.perform

          # Check that the subscriptions exactly match the defaults for the demo user
          default_subscriptions.keys.each do |folder_title|
            if folder_title == Folder::NO_FOLDER
              folder = folder_title
            else
              folder = Folder.find_by_title folder_title
              expect(@demo_user.folders).to include folder
            end

            expect(@demo_user.folder_feeds(folder, include_read: true).map {|f| f.fetch_url}).to match_array default_subscriptions[folder_title]
          end
        end
      end

      context 'reset entries' do
        
        before :each do
          default_subscriptions = Feedbunch::Application.config.demo_subscriptions
          
          # There are two read entries in one of the demo feeds
          @demo_feed_url = default_subscriptions.values.flatten.first
          @demo_feed = FactoryGirl.create :feed, fetch_url: @demo_feed_url

          @entry_1 = FactoryGirl.build :entry, feed_id: @demo_feed.id
          @entry_2 = FactoryGirl.build :entry, feed_id: @demo_feed.id
          @demo_feed.entries << @entry_1 << @entry_2
          @demo_user.subscribe @demo_feed.fetch_url
          @demo_user.change_entries_state @entry_1, 'read'
          @demo_user.change_entries_state @entry_2, 'read'
        end

        it 'marks all entries as unread' do
          expect(@entry_1.read_by? @demo_user).to be true
          expect(@entry_2.read_by? @demo_user).to be true

          ResetDemoUserWorker.new.perform

          expect(@entry_1.read_by? @demo_user).to be false
          expect(@entry_2.read_by? @demo_user).to be false
        end

        it 'sets correct unread count in subscriptions' do
          expect(@demo_user.feed_unread_count @demo_feed).to eq 0

          ResetDemoUserWorker.new.perform

          expect(@demo_user.feed_unread_count @demo_feed).to eq 2
        end
      end
    end
  end

end