require 'spec_helper'

describe User do
  before :each do
    @user = FactoryGirl.create :user
  end

  context 'validations' do
    it 'does not allow duplicate usernames' do
      user_dupe = FactoryGirl.build :user, email: @user.email
      user_dupe.valid?.should be_false
    end
  end

  context 'relationship with feeds' do
    it 'returns feeds the user is suscribed to' do
      feed1 = FactoryGirl.create :feed
      feed2 = FactoryGirl.create :feed
      @user.subscribe feed1.fetch_url
      @user.subscribe feed2.fetch_url
      @user.feeds.include?(feed1).should be_true
      @user.feeds.include?(feed2).should be_true
    end

    it 'does not return feeds the user is not suscribed to' do
      feed = FactoryGirl.create :feed
      @user.feeds.include?(feed).should be_false
    end

    it 'does not allow subscribing to the same feed more than once' do
      feed = FactoryGirl.create :feed
      @user.subscribe feed.fetch_url
      expect {@user.subscribe feed.fetch_url}.to raise_error
      @user.feeds.count.should eq 1
      @user.feeds.first.should eq feed
    end

    context 'add subscription' do

      before :each do
        @feed = FactoryGirl.create :feed
      end

      it 'rejects non-valid URLs' do
        invalid_url = 'not-an-url'
        expect{@user.subscribe invalid_url}.to raise_error
        @user.feeds.where(fetch_url: invalid_url).should be_blank
        @user.feeds.where(url: invalid_url).should be_blank
      end

      it 'accepts URLs without scheme, defaults to http://' do
        url = 'xkcd.com'
        FeedClient.stub :fetch do |id, perform_autodiscovery|
          feed = Feed.find id
          feed
        end

        result = @user.subscribe url

        result.should be_present
        feed = @user.feeds.where(fetch_url: 'http://'+url).first
        feed.should be_present
        result.should eq feed
      end

      it 'accepts URLs with feed:// scheme, defaults to http://' do
        url_feed = 'feed://xkcd.com'
        url_http = 'http://xkcd.com'
        FeedClient.stub :fetch do |id, perform_autodiscovery|
          feed = Feed.find id
          feed
        end

        result = @user.subscribe url_feed

        result.should be_present
        feed = @user.feeds.where(fetch_url: url_http).first
        feed.should be_present
        result.should eq feed
      end

      it 'accepts URLs with feed: scheme, defaults to http://' do
        url_feed = 'feed:http://xkcd.com'
        url_http = 'http://xkcd.com'
        FeedClient.stub :fetch do |id, perform_autodiscovery|
          feed = Feed.find id
          feed
        end

        result = @user.subscribe url_feed

        result.should be_present
        feed = @user.feeds.where(fetch_url: url_http).first
        feed.should be_present
        result.should eq feed
      end

      it 'subscribes to the feed actually fetched, not necessarily to a new one' do
        url = 'xkcd.com'
        existing_feed = FactoryGirl.create :feed
        FeedClient.stub :fetch do
          existing_feed
        end

        result = @user.subscribe url

        result.should eq existing_feed
        @user.feeds.count.should eq 1
        @user.feeds.should include existing_feed
      end

      it 'raises an error if user tries to subscribe twice to a feed, given its fetch_url' do
        # User is already subscribed to the feed
        @user.subscribe @feed.fetch_url

        # The feed is already in the database, no attempt to save it should happen
        Feed.any_instance.should_not_receive :save

        # Feed already should have entries in the database, no attempt to fetch it should happen
        FeedClient.should_not_receive :fetch

        expect{@user.subscribe @feed.fetch_url}.to raise_error AlreadySubscribedError
      end

      it 'raises an error if user tries to subscribe twice to a feed, given its fetch_url missing a trailing slash' do
        feed_url = 'http://some.host/feed/'
        url_no_slash = 'http://some.host/feed'
        feed = FactoryGirl.create :feed, fetch_url: feed_url
        # User is already subscribed to the feed
        @user.subscribe feed.fetch_url

        # The feed is already in the database, no attempt to save it should happen
        Feed.any_instance.should_not_receive :save

        # Feed already should have entries in the database, no attempt to fetch it should happen
        FeedClient.should_not_receive :fetch

        expect{@user.subscribe url_no_slash}.to raise_error AlreadySubscribedError
      end

      it 'raises an error if user tries to subscribe twice to a feed, given its fetch_url with an added trailing slash' do
        feed_url = 'http://some.host/feed'
        url_slash = 'http://some.host/feed/'
        feed = FactoryGirl.create :feed, fetch_url: feed_url
        # User is already subscribed to the feed
        @user.subscribe feed.fetch_url

        # The feed is already in the database, no attempt to save it should happen
        Feed.any_instance.should_not_receive :save

        # Feed already should have entries in the database, no attempt to fetch it should happen
        FeedClient.should_not_receive :fetch

        expect{@user.subscribe url_slash}.to raise_error AlreadySubscribedError
      end

      it 'raises an error if user tries to subscribe twice to a feed, given its fetch_url without URI-scheme' do
        feed_url = 'http://some.host/feed/'
        url_no_scheme = 'some.host/feed/'
        feed = FactoryGirl.create :feed, fetch_url: feed_url
        # User is already subscribed to the feed
        @user.subscribe feed.fetch_url

        # The feed is already in the database, no attempt to save it should happen
        Feed.any_instance.should_not_receive :save

        # Feed already should have entries in the database, no attempt to fetch it should happen
        FeedClient.should_not_receive :fetch

        expect{@user.subscribe url_no_scheme}.to raise_error AlreadySubscribedError
      end

      it 'subscribes user to feed already in the database, given its fetch_url' do
        # At first the user is not subscribed to the feed
        @user.feeds.where(fetch_url: @feed.fetch_url).should be_blank

        # The feed is already in the database, no attempt to save it should happen
        Feed.any_instance.should_not_receive :save

        # Feed already should have entries in the database, no attempt to fetch it should happen
        FeedClient.should_not_receive :fetch

        result = @user.subscribe @feed.fetch_url
        result.should eq @feed
        @user.feeds.where(fetch_url: @feed.fetch_url).first.should eq @feed
      end

      it 'subscribes user to feed already in the database, given its fetch_url with added trailing slash' do
        url = 'http://some.host/feed'
        url_slash = 'http://some.host/feed/'
        # At first the user is not subscribed to the feed
        feed = FactoryGirl.create :feed, fetch_url: url
        @user.feeds.where(fetch_url: feed.fetch_url).should be_blank

        # The feed is already in the database, no attempt to save it should happen
        Feed.any_instance.should_not_receive :save

        # Feed already should have entries in the database, no attempt to fetch it should happen
        FeedClient.should_not_receive :fetch

        result = @user.subscribe url_slash
        result.should eq feed
        @user.feeds.where(fetch_url: feed.fetch_url).first.should eq feed
      end

      it 'subscribes user to feed already in the database, given its fetch_url missing a trailing slash' do
        url = 'http://some.host/feed/'
        url_no_slash = 'http://some.host/feed'
        # At first the user is not subscribed to the feed
        feed = FactoryGirl.create :feed, fetch_url: url
        @user.feeds.where(fetch_url: feed.fetch_url).should be_blank

        # The feed is already in the database, no attempt to save it should happen
        Feed.any_instance.should_not_receive :save

        # Feed already should have entries in the database, no attempt to fetch it should happen
        FeedClient.should_not_receive :fetch

        result = @user.subscribe url_no_slash
        result.should eq feed
        @user.feeds.where(fetch_url: feed.fetch_url).first.should eq feed
      end

      it 'subscribes user to feed already in the database, given its fetch_url without uri-scheme' do
        url = 'http://some.host/feed/'
        url_no_scheme = 'some.host/feed/'
        # At first the user is not subscribed to the feed
        feed = FactoryGirl.create :feed, fetch_url: url
        @user.feeds.where(fetch_url: feed.fetch_url).should be_blank

        # The feed is already in the database, no attempt to save it should happen
        Feed.any_instance.should_not_receive :save

        # Feed already should have entries in the database, no attempt to fetch it should happen
        FeedClient.should_not_receive :fetch

        result = @user.subscribe url_no_scheme
        result.should eq feed
        @user.feeds.where(fetch_url: feed.fetch_url).first.should eq feed
      end

      it 'raises an error if user tries to subscribe twice to a feed, given its url' do
        # User is already subscribed to the feed
        @user.subscribe @feed.fetch_url

        # The feed is already in the database, no attempt to save it should happen
        Feed.any_instance.should_not_receive :save

        # Feed already should have entries in the database, no attempt to fetch it should happen
        FeedClient.should_not_receive :fetch

        expect{@user.subscribe @feed.url}.to raise_error AlreadySubscribedError
      end

      it 'raises an error if user tries to subscribe twice to a feed, given its url missing a trailing slash' do
        feed_url = 'http://some.host/feed/'
        url_no_slash = 'http://some.host/feed'
        feed = FactoryGirl.create :feed, url: feed_url
        # User is already subscribed to the feed
        @user.subscribe feed.fetch_url

        # The feed is already in the database, no attempt to save it should happen
        Feed.any_instance.should_not_receive :save

        # Feed already should have entries in the database, no attempt to fetch it should happen
        FeedClient.should_not_receive :fetch

        expect{@user.subscribe url_no_slash}.to raise_error AlreadySubscribedError
      end

      it 'raises an error if user tries to subscribe twice to a feed, given its url with an added trailing slash' do
        feed_url = 'http://some.host/feed'
        url_slash = 'http://some.host/feed/'
        feed = FactoryGirl.create :feed, url: feed_url
        # User is already subscribed to the feed
        @user.subscribe feed.fetch_url

        # The feed is already in the database, no attempt to save it should happen
        Feed.any_instance.should_not_receive :save

        # Feed already should have entries in the database, no attempt to fetch it should happen
        FeedClient.should_not_receive :fetch

        expect{@user.subscribe url_slash}.to raise_error AlreadySubscribedError
      end

      it 'raises an error if user tries to subscribe twice to a feed, given its url without URI-scheme' do
        feed_url = 'http://some.host/feed/'
        url_no_scheme = 'some.host/feed/'
        feed = FactoryGirl.create :feed, url: feed_url
        # User is already subscribed to the feed
        @user.subscribe feed.fetch_url

        # The feed is already in the database, no attempt to save it should happen
        Feed.any_instance.should_not_receive :save

        # Feed already should have entries in the database, no attempt to fetch it should happen
        FeedClient.should_not_receive :fetch

        expect{@user.subscribe url_no_scheme}.to raise_error AlreadySubscribedError
      end

      it 'subscribes user to feed already in the database, given its url' do
        # At first the user is not subscribed to the feed
        @user.feeds.where(url: @feed.url).should be_blank

        # The feed is already in the database, no attempt to save it should happen
        Feed.any_instance.should_not_receive :save

        # Feed already should have entries in the database, no attempt to fetch it should happen
        FeedClient.should_not_receive :fetch

        result = @user.subscribe @feed.url
        result.should eq @feed
        @user.feeds.where(url: @feed.url).first.should eq @feed
      end

      it 'subscribes user to feed already in the database, given its url with added trailing slash' do
        url = 'http://some.host/feed'
        url_slash = 'http://some.host/feed/'
        # At first the user is not subscribed to the feed
        feed = FactoryGirl.create :feed, url: url
        @user.feeds.where(url: feed.fetch_url).should be_blank

        # The feed is already in the database, no attempt to save it should happen
        Feed.any_instance.should_not_receive :save

        # Feed already should have entries in the database, no attempt to fetch it should happen
        FeedClient.should_not_receive :fetch

        result = @user.subscribe url_slash
        result.should eq feed
        @user.feeds.where(url: feed.url).first.should eq feed
      end

      it 'subscribes user to feed already in the database, given its url missing a trailing slash' do
        url = 'http://some.host/feed/'
        url_no_slash = 'http://some.host/feed'
        # At first the user is not subscribed to the feed
        feed = FactoryGirl.create :feed, url: url
        @user.feeds.where(url: feed.fetch_url).should be_blank

        # The feed is already in the database, no attempt to save it should happen
        Feed.any_instance.should_not_receive :save

        # Feed already should have entries in the database, no attempt to fetch it should happen
        FeedClient.should_not_receive :fetch

        result = @user.subscribe url_no_slash
        result.should eq feed
        @user.feeds.where(url: feed.url).first.should eq feed
      end

      it 'subscribes user to feed already in the database, given its url without uri-scheme' do
        url = 'http://some.host/feed/'
        url_no_scheme = 'some.host/feed/'
        # At first the user is not subscribed to the feed
        feed = FactoryGirl.create :feed, url: url
        @user.feeds.where(url: feed.fetch_url).should be_blank

        # The feed is already in the database, no attempt to save it should happen
        Feed.any_instance.should_not_receive :save

        # Feed already should have entries in the database, no attempt to fetch it should happen
        FeedClient.should_not_receive :fetch

        result = @user.subscribe url_no_scheme
        result.should eq feed
        @user.feeds.where(url: feed.url).first.should eq feed
      end

      it 'adds new feed to the database and subscribes user to it' do
        feed_url = 'http://a.new.feed.url.com'
        entry_title1 = 'an entry title'
        entry_title2 = 'another entry title'
        FeedClient.stub :fetch do
          feed = Feed.where(fetch_url: feed_url).first
          entry1 = FactoryGirl.build :entry, feed_id: feed.id, title: entry_title1
          entry2 = FactoryGirl.build :entry, feed_id: feed.id, title: entry_title2
          feed.entries << entry1 << entry2
          feed
        end

        # At first the user is not subscribed to the feed
        @user.feeds.where(fetch_url: feed_url).should be_blank

        @user.subscribe feed_url
        @user.feeds.where(fetch_url: feed_url).should be_present
        @user.feeds.where(fetch_url: feed_url).first.entries.count.should eq 2
        @user.feeds.where(fetch_url: feed_url).first.entries.where(title: entry_title1).should be_present
        @user.feeds.where(fetch_url: feed_url).first.entries.where(title: entry_title2).should be_present
      end

      it 'does not save in the database if there is a problem fetching the feed' do
        feed_url = 'http://a.new.feed.url.com'
        FeedClient.stub fetch: nil

        # At first the user is not subscribed to any feed
        @user.feeds.should be_blank
        @user.subscribe feed_url
        # User should still be subscribed to no feeds, and the feed should not be saved in the database
        @user.feeds.should be_blank
        Feed.where(fetch_url: feed_url).should be_blank
        Feed.where(url: feed_url).should be_blank
      end

      it 'does not save in the database if feed autodiscovery fails' do
        feed_url = 'http://a.new.feed.url.com'
        FeedClient.stub(:fetch).and_raise FeedAutodiscoveryError.new

        # At first the user is not subscribed to any feed
        @user.feeds.should be_blank
        expect {@user.subscribe feed_url}.to raise_error FeedAutodiscoveryError
        # User should still be subscribed to no feeds, and the feed should not be saved in the database
        @user.feeds.should be_blank
        Feed.where(fetch_url: feed_url).should be_blank
        Feed.where(url: feed_url).should be_blank
      end

      it 'returns false if it cannot fetch the feed' do
        feed_url = 'http://a.new.feed.url.com'
        FeedClient.stub fetch: nil

        # At first the user is not subscribed to any feed
        success = @user.subscribe feed_url
        success.should be_false
      end
    end

    context 'unsubscribe from feed' do

      before :each do
        @feed = FactoryGirl.create :feed
        @user.subscribe @feed.fetch_url
      end

      it 'unsubscribes a user from a feed' do
        @user.feeds.exists?(@feed.id).should be_true
        @user.unsubscribe @feed.id
        @user.feeds.exists?(@feed.id).should be_false
      end

      it 'returns nil if feed was not in a folder' do
        @user.feeds.exists?(@feed.id).should be_true
        folder_unchanged = @user.unsubscribe @feed.id
        folder_unchanged.should be_nil
      end

      it 'returns folder id if feed was in a folder' do
        folder = FactoryGirl.build :folder, user_id: @user.id
        @user.folders << folder
        folder.feeds << @feed

        old_folder = @user.unsubscribe @feed.id
        old_folder.should eq folder
      end

      it 'raises error if the user is not subscribed to the feed' do
        feed2 = FactoryGirl.create :feed
        expect {@user.unsubscribe feed2.id}.to raise_error ActiveRecord::RecordNotFound
      end

      it 'raises an error if there is a problem unsubscribing' do
        User.any_instance.stub(:feeds).and_raise StandardError.new
        expect {@user.unsubscribe @feed.id}.to raise_error
      end

      it 'does not change subscriptions to the feed by other users' do
        user2 = FactoryGirl.create :user
        user2.subscribe @feed.fetch_url

        @user.feeds.exists?(@feed.id).should be_true
        user2.feeds.exists?(@feed.id).should be_true

        @user.unsubscribe @feed.id
        Feed.exists?(@feed.id).should be_true
        @user.feeds.exists?(@feed.id).should be_false
        user2.feeds.exists?(@feed.id).should be_true
      end

      it 'completely deletes feed if there are no more users subscribed' do
        Feed.exists?(@feed.id).should be_true

        @user.unsubscribe @feed.id

        Feed.exists?(@feed.id).should be_false
      end

      it 'does not delete feed if there are more users subscribed' do
        user2 = FactoryGirl.create :user
        user2.subscribe @feed.fetch_url

        @user.unsubscribe @feed.id
        Feed.exists?(@feed).should be_true
      end

    end
  end

  context 'relationship with folders' do
    before :each do
      @folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << @folder
    end

    it 'deletes folders when deleting a user' do
      Folder.count.should eq 1
      @user.destroy
      Folder.count.should eq 0
    end

    it 'does not allow associating to the same folder more than once' do
      @user.folders.count.should eq 1
      @user.folders.should include @folder

      @user.folders << @folder

      @user.folders.count.should eq 1
      @user.folders.first.should eq @folder
    end

    it 'retrieves unread entries from a folder' do
      # feed1 and feed2 are in @folder
      feed1 = FactoryGirl.create :feed
      feed2 = FactoryGirl.create :feed
      @user.subscribe feed1.fetch_url
      @user.subscribe feed2.fetch_url
      entry1 = FactoryGirl.build :entry, feed_id: feed1.id
      entry2 = FactoryGirl.build :entry, feed_id: feed1.id
      entry3 = FactoryGirl.build :entry, feed_id: feed1.id
      feed1.entries << entry1 << entry2
      feed2.entries << entry3
      @folder.feeds << feed1 << feed2

      # entry1 is read, entry2 and entry3 are unread
      entry_state1 = EntryState.where(user_id: @user.id, entry_id: entry1.id).first
      entry_state1.read = true
      entry_state1.save!

      entries = @user.unread_folder_entries @folder.id
      entries.count.should eq 2
      entries.should include entry2
      entries.should include entry3
    end

    it 'retrieves unread entries for all subscribed feeds' do
      # feed1 is in @folder; feed2 is subscribed, but it's not in any folder
      feed1 = FactoryGirl.create :feed
      feed2 = FactoryGirl.create :feed
      @user.subscribe feed1.fetch_url
      @user.subscribe feed2.fetch_url
      entry1 = FactoryGirl.build :entry, feed_id: feed1.id
      entry2 = FactoryGirl.build :entry, feed_id: feed1.id
      entry3 = FactoryGirl.build :entry, feed_id: feed1.id
      feed1.entries << entry1 << entry2
      feed2.entries << entry3
      @folder.feeds << feed1

      # entry1 is read, entry2 and entry3 are unread
      entry_state1 = EntryState.where(user_id: @user.id, entry_id: entry1.id).first
      entry_state1.read = true
      entry_state1.save!

      entries = @user.unread_folder_entries 'all'
      entries.count.should eq 2
      entries.should include entry2
      entries.should include entry3
    end

    it 'raises an error trying to retrieve entries from a folder that does not belong to the user' do
      folder2 = FactoryGirl.create :folder
      expect{@user.unread_folder_entries folder2.id}.to raise_error ActiveRecord::RecordNotFound
    end
  end

  context 'relationship with entries' do
    it 'retrieves all entries for all subscribed feeds' do
      feed1 = FactoryGirl.create :feed
      feed2 = FactoryGirl.create :feed
      @user.subscribe feed1.fetch_url
      @user.subscribe feed2.fetch_url
      entry1 = FactoryGirl.build :entry, feed_id: feed1.id
      entry2 = FactoryGirl.build :entry, feed_id: feed1.id
      entry3 = FactoryGirl.build :entry, feed_id: feed2.id
      feed1.entries << entry1 << entry2
      feed2.entries << entry3

      @user.entries.count.should eq 3
      @user.entries.should include entry1
      @user.entries.should include entry2
      @user.entries.should include entry3
    end
  end

  context 'relationship with entry states' do
    it 'retrieves entry states for subscribed feeds' do
      entry_state1 = FactoryGirl.build :entry_state, user_id: @user.id
      entry_state2 = FactoryGirl.build :entry_state, user_id: @user.id
      @user.entry_states << entry_state1
      @user.entry_states << entry_state2


      @user.entry_states.count.should eq 2
      @user.entry_states.should include entry_state1
      @user.entry_states.should include entry_state2
    end

    it 'deletes entry states when deleting a user' do
      entry_state = FactoryGirl.build :entry_state, user_id: @user.id
      @user.entry_states << entry_state

      EntryState.count.should eq 1
      @user.destroy
      EntryState.count.should eq 0
    end

    it 'does not allow duplicate entry states' do
      entry_state = FactoryGirl.build :entry_state, user_id: @user.id
      @user.entry_states << entry_state
      @user.entry_states << entry_state

      @user.entry_states.count.should eq 1
    end

    it 'saves unread entry states for all feed entries when subscribing to a feed' do
      feed = FactoryGirl.create :feed
      entry1 = FactoryGirl.build :entry, feed_id: feed.id
      entry2 = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry1 << entry2

      @user.subscribe feed.fetch_url
      @user.entry_states.count.should eq 2
      @user.entry_states.where(entry_id: entry1.id, read: false).should be_present
      @user.entry_states.where(entry_id: entry2.id, read: false).should be_present
    end

    it 'removes entry states for all feed entries when unsubscribing from a feed' do
      feed = FactoryGirl.create :feed
      entry1 = FactoryGirl.build :entry, feed_id: feed.id
      entry2 = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry1 << entry2
      @user.subscribe feed.fetch_url

      @user.entry_states.count.should eq 2
      @user.feeds.delete feed
      @user.entry_states.count.should eq 0
    end

    it 'does not affect entry states for other feeds when unsubscribing from a feed' do
      feed1 = FactoryGirl.create :feed
      entry1 = FactoryGirl.build :entry, feed_id: feed1.id
      feed1.entries << entry1
      feed2 = FactoryGirl.create :feed
      entry2 = FactoryGirl.build :entry, feed_id: feed2.id
      feed2.entries << entry2
      @user.subscribe feed1.fetch_url
      @user.subscribe feed2.fetch_url

      @user.entry_states.count.should eq 2
      @user.feeds.delete feed1
      @user.entry_states.count.should eq 1
      @user.entry_states.where(user_id: @user.id, entry_id: entry2.id).should be_present
    end

    it 'retrieves unread entries in a feed' do
      feed = FactoryGirl.create :feed
      entry1 = FactoryGirl.build :entry, feed_id: feed.id
      entry2 = FactoryGirl.build :entry, feed_id: feed.id
      entry3 = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry1 << entry2 << entry3
      @user.subscribe feed.fetch_url

      # Mark one of the three entries as read by user
      entry_state = EntryState.where(entry_id: entry3.id, user_id: @user.id).first
      entry_state.read = true
      entry_state.save!

      entries = @user.feed_entries feed.id
      entries.count.should eq 2
      entries.should include entry1
      entries.should include entry2
      entries.should_not include entry3
    end

    it 'retrieves read and unread entries in a feed' do
      feed = FactoryGirl.create :feed
      entry1 = FactoryGirl.build :entry, feed_id: feed.id
      entry2 = FactoryGirl.build :entry, feed_id: feed.id
      entry3 = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry1 << entry2 << entry3
      @user.subscribe feed.fetch_url

      # Mark one of the three entries as read by user
      entry_state = EntryState.where(entry_id: entry3.id, user_id: @user.id).first
      entry_state.read = true
      entry_state.save!

      entries = @user.feed_entries feed.id, true
      entries.count.should eq 3
      entries.should include entry1
      entries.should include entry2
      entries.should include entry3
    end

    it 'raises an error trying to retrieve unread entries from an unsubscribed feed' do
      feed = FactoryGirl.create :feed
      entry = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry

      expect {@user.feed_entries feed.id}.to raise_error ActiveRecord::RecordNotFound
    end
  end

  context 'relationship with data_imports' do

    before :each do
      @data_import = FactoryGirl.build :data_import, user_id: @user.id
      @user.data_import = @data_import
    end

    it 'deletes data_imports when deleting a user' do
      DataImport.count.should eq 1
      @user.destroy
      DataImport.count.should eq 0
    end

    it 'deletes the old data_import when adding a new one for a user' do
      DataImport.exists?(@data_import).should be_true
      data_import2 = FactoryGirl.build :data_import, user_id: @user.id
      @user.data_import = data_import2

      DataImport.exists?(@data_import).should be_false
    end
  end

  context 'refresh feed' do
    before :each do
      @feed = FactoryGirl.create :feed
      @user.subscribe @feed.fetch_url
    end

    it 'fetches a feed' do
      FeedClient.should_receive(:fetch).with @feed.id, anything
      @user.refresh_feed @feed.id
    end

    it 'returns unread entries from the feed' do
      # @user is subscribed to feed2, which has entries entry1, entry2
      feed2 = FactoryGirl.create :feed
      entry1 = FactoryGirl.build :entry, feed_id: feed2.id
      entry2 = FactoryGirl.build :entry, feed_id: feed2.id
      feed2.entries << entry1 << entry2
      @user.subscribe feed2.fetch_url
      # entry1 is read, entry2 is unread
      entry_state1 = EntryState.where(entry_id: entry1.id, user_id: @user.id).first
      entry_state1.read = true
      entry_state1.save!
      # fetches a new entry (unread by default)
      entry3 = FactoryGirl.build :entry, feed_id: feed2.id
      FeedClient.stub :fetch do
        feed2.entries << entry3
        feed2
      end

      # refresh should return the "old" unread entry and the new (just fetched) entry
      entries = @user.refresh_feed feed2.id
      entries.count.should eq 2
      entries.should include entry2
      entries.should include entry3
    end

    it 'raises an error trying to refresh a feed the user is not subscribed to' do
      feed2 = FactoryGirl.create :feed
      expect {@user.refresh_feed feed2.id}.to raise_error ActiveRecord::RecordNotFound
    end
  end

  context 'add feed to folder' do
    before :each do
      @folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << @folder
      @feed = FactoryGirl.create :feed
      @user.subscribe @feed.fetch_url
    end

    it 'adds a feed to a folder' do
      @folder.feeds.should be_blank
      @user.add_feed_to_folder @feed.id, @folder.id
      @folder.reload
      @folder.feeds.count.should eq 1
      @folder.feeds.should include @feed
    end

    it 'removes the feed from its old folder' do
      feed2 = FactoryGirl.create :feed
      @user.subscribe feed2.fetch_url
      @folder.feeds << @feed
      @folder.feeds << feed2

      folder2 = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder2

      @user.add_feed_to_folder @feed.id, folder2.id

      @folder.reload
      @folder.feeds.should_not include @feed
    end

    it 'does not change feed/folder if asked to move feed to the same folder' do
      @folder.feeds << @feed

      @user.add_feed_to_folder @feed.id, @folder.id

      @folder.feeds.count.should eq 1
      @folder.feeds.should include @feed
    end

    it 'returns the feed' do
      folders = @user.add_feed_to_folder @feed.id, @folder.id
      folders[:feed].should eq @feed
    end

    it 'returns the new folder' do
      folders = @user.add_feed_to_folder @feed.id, @folder.id
      folders[:new_folder].should eq @folder
    end

    it 'returns the old folder' do
      @folder.feeds << @feed
      folder2 = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder2

      folders = @user.add_feed_to_folder @feed.id, folder2.id
      folders[:old_folder].should eq @folder
    end

    it 'does not return the old folder if the feed was not in a folder' do
      folders = @user.add_feed_to_folder @feed.id, @folder.id
      folders[:old_folder].should be_nil
    end

    it 'deletes the old folder if it had no more feeds' do
      @folder.feeds << @feed
      folder2 = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder2

      @user.add_feed_to_folder @feed.id, folder2.id

      Folder.exists?(id: @folder.id).should be_false
    end

    it 'does not delete the old folder if it has more feeds' do
      feed2 = FactoryGirl.create :feed
      @user.subscribe feed2.fetch_url
      @folder.feeds << @feed << feed2
      folder2 = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder2

      @user.add_feed_to_folder @feed.id, folder2.id

      Folder.exists?(id: @folder.id).should be_true
    end

    it 'raises an error if the folder does not belong to the user' do
      folder = FactoryGirl.create :folder
      expect {@user.add_feed_to_folder @feed.id, folder.id}.to raise_error ActiveRecord::RecordNotFound
    end

    it 'raises an error if the user is not subscribed to the feed' do
      feed = FactoryGirl.create :feed
      expect {@user.add_feed_to_folder feed.id, @folder.id}.to raise_error ActiveRecord::RecordNotFound
    end
  end

  context 'remove feed from folder' do

    before :each do
      @feed = FactoryGirl.create :feed
      @user.subscribe @feed.fetch_url
      @folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << @folder
      @folder.feeds << @feed
    end

    it 'removes a feed from a folder' do
      @folder.feeds.count.should eq 1
      @user.remove_feed_from_folder @feed.id
      @folder.feeds.count.should eq 0
    end

    it 'deletes the folder if it is empty' do
      @user.remove_feed_from_folder @feed.id
      Folder.exists?(id: @folder.id).should be_false
    end

    it 'does not delete the folder if it is not empty' do
      feed2 = FactoryGirl.create :feed
      @user.subscribe feed2.fetch_url
      @folder.feeds << feed2

      @user.remove_feed_from_folder @feed.id
      Folder.exists?(id: @folder.id).should be_true
    end

    it 'returns the folder object if it the feed was in a folder' do
      folder = @user.remove_feed_from_folder @feed.id
      folder.should eq @folder
    end

    it 'does not return a folder object if it the feed was not in a folder' do
      feed2 = FactoryGirl.create :feed
      @user.subscribe feed2.fetch_url

      folder = @user.remove_feed_from_folder feed2.id
      folder.should be_nil
    end

    it 'returns a folder object with no feeds if there are no more feeds in it' do
      folder = @user.remove_feed_from_folder @feed.id
      folder.feeds.blank?.should be_true
    end

    it 'returns a folder object with feeds if there are more feeds in it' do
      feed2 = FactoryGirl.create :feed
      @user.subscribe feed2.fetch_url
      @folder.feeds << feed2

      folder = @user.remove_feed_from_folder @feed.id
      folder.feeds.blank?.should be_false
    end

    it 'raises an error if the user is not subscribed to the feed' do
      feed2 = FactoryGirl.create :feed
      expect {@user.remove_feed_from_folder feed2.id}.to raise_error ActiveRecord::RecordNotFound
    end

  end

  context 'add feed to new folder' do
    before :each do
      @feed = FactoryGirl.create :feed
      @user.subscribe @feed.fetch_url
      @title = 'New folder'
    end

    it 'creates new folder' do
      @user.add_feed_to_new_folder @feed.id, @title

      @user.reload
      @user.folders.where(title: @title).should be_present
    end

    it 'adds feed to new folder' do
      @user.add_feed_to_new_folder @feed.id, @title
      @user.reload

      folder = @user.folders.where(title: @title).first
      folder.feeds.count.should eq 1
      folder.feeds.should include @feed
    end

    it 'removes feed from its old folder' do
      folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      folder.feeds << @feed

      folder.feeds.count.should eq 1
      @user.add_feed_to_new_folder @feed.id, @title
      folder.feeds.count.should eq 0
    end

    it 'deletes old folder if it has no more feeds' do
      folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      folder.feeds << @feed

      @user.add_feed_to_new_folder @feed.id, @title
      Folder.exists?(folder).should be_false
    end

    it 'does not delete old folder if it has more feeds' do
      folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      feed2 = FactoryGirl.create :feed
      @user.subscribe feed2.fetch_url
      folder.feeds << @feed << feed2

      @user.add_feed_to_new_folder @feed.id, @title
      Folder.exists?(folder).should be_true
    end

    it 'returns the new folder' do
      changed_data = @user.add_feed_to_new_folder @feed.id, @title
      folder = @user.folders.where(title: @title).first

      changed_data[:new_folder].should eq folder
    end

    it 'returns the old folder' do
      folder = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      folder.feeds << @feed

      changed_data = @user.add_feed_to_new_folder @feed.id, @title

      changed_data[:old_folder].should eq folder
    end

    it 'does not return the old folder if the feed was not in any folder' do
      changed_data = @user.add_feed_to_new_folder @feed.id, @title
      changed_data.keys.should_not include :old_folder
    end

    it 'raises an error if the user already has a folder with the same title' do
      folder = FactoryGirl.build :folder, user_id: @user.id, title: @title
      @user.folders << folder
      expect {@user.add_feed_to_new_folder @feed.id, @title}.to raise_error FolderAlreadyExistsError
    end

    it 'does not raise an error if another user has a folder with the same title' do
      user2 = FactoryGirl.create :user
      folder2 = FactoryGirl.build :folder, user_id: user2.id, title: @title
      user2.folders << folder2

      expect {@user.add_feed_to_new_folder @feed.id, @title}.to_not raise_error
    end

    it 'raises an error if user is not subscribed to the feed' do
      feed2 = FactoryGirl.create :feed
      expect {@user.add_feed_to_new_folder feed2.id, @title}.to raise_error ActiveRecord::RecordNotFound
    end
  end

  context 'change entry state' do

    before :each do
      @feed = FactoryGirl.create :feed
      @user.subscribe @feed.fetch_url
      @entry = FactoryGirl.build :entry, feed_id: @feed.id
      @feed.entries << @entry
    end

    it 'marks entry as read' do
      entry_state = EntryState.where(user_id: @user.id, entry_id: @entry.id).first
      entry_state.read.should be_false

      @user.change_entry_state [@entry.id], 'read'
      entry_state.reload
      entry_state.read.should be_true
    end

    it 'returns changed feeds and folders' do
      folder= FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      folder.feeds << @feed

      changed_data = @user.change_entry_state [@entry.id], 'read'

      changed_data[:feeds].length.should eq 1
      changed_data[:feeds][0].should eq @feed

      changed_data[:folders].length.should eq 1
      changed_data[:folders][0].should eq folder
    end

    it 'marks entry as unread' do
      entry_state = EntryState.where(user_id: @user.id, entry_id: @entry.id).first
      entry_state.read = true
      entry_state.save

      @user.change_entry_state [@entry.id], 'unread'
      entry_state.reload
      entry_state.read.should be_false
    end

    it 'marks several entries as read' do
      entry2 = FactoryGirl.build :entry, feed_id: @feed.id
      @feed.entries << entry2

      entry_state1 = EntryState.where(user_id: @user.id, entry_id: @entry.id).first
      entry_state1.read.should be_false
      entry_state2 = EntryState.where(user_id: @user.id, entry_id: entry2.id).first
      entry_state2.read.should be_false

      @user.change_entry_state [@entry.id, entry2.id], 'read'
      entry_state1.reload
      entry_state1.read.should be_true
      entry_state2.reload
      entry_state2.read.should be_true
    end

    it 'marks several entries as unread' do
      entry2 = FactoryGirl.build :entry, feed_id: @feed.id
      @feed.entries << entry2

      entry_state1 = EntryState.where(user_id: @user.id, entry_id: @entry.id).first
      entry_state1.read = true
      entry_state1.save
      entry_state2 = EntryState.where(user_id: @user.id, entry_id: entry2.id).first
      entry_state2.read = true
      entry_state2.save

      @user.change_entry_state [@entry.id, entry2.id], 'unread'
      entry_state1.reload
      entry_state1.read.should be_false
      entry_state2.reload
      entry_state2.read.should be_false
    end

    it 'does not change an entry state if passed an unknown state' do
      entry_state = EntryState.where(user_id: @user.id, entry_id: @entry.id).first
      entry_state.read.should be_false

      @user.change_entry_state [@entry.id], 'somethingsomethingsomething'
      entry_state.reload
      entry_state.read.should be_false

      entry_state.read = true
      entry_state.save

      @user.change_entry_state [@entry.id], 'somethingsomethingsomething'
      entry_state.reload
      entry_state.read.should be_true
    end

    it 'raises an error if the entry is not from a feed the user is subscribed to' do
      entry2 = FactoryGirl.create :entry
      expect {@user.change_entry_state [entry2.id], 'read'}.to raise_error ActiveRecord::RecordNotFound
    end

    it 'does not change state for other users' do
      user2 = FactoryGirl.create :user
      user2.subscribe @feed.fetch_url

      @user.change_entry_state [@entry.id], 'read'

      entry_state2 = EntryState.where(user_id: user2.id, entry_id: @entry.id).first
      entry_state2.read.should be false
    end
  end

  context 'import subscriptions' do

    before :each do
      @opml_data = File.read File.join(File.dirname(__FILE__), '..', 'attachments', 'subscriptions.xml')
      @data_file = File.open File.join(File.dirname(__FILE__), '..', 'attachments', 'feedbunch@gmail.com-takeout.zip')

      Feedbunch::Application.config.uploads_manager.stub read: @opml_data
      Feedbunch::Application.config.uploads_manager.stub :save
      Feedbunch::Application.config.uploads_manager.stub :delete

      timestamp = 1371146348
      Time.stub(:now).and_return Time.at(timestamp)
      @filename = "#{timestamp}.opml"
    end

    it 'creates a new data_import with status RUNNING for the user' do
      @user.data_import.should be_blank
      @user.import_subscriptions @data_file

      @user.data_import.should be_present
      @user.data_import.status.should eq DataImport::RUNNING
    end

    it 'sets data_import status as ERROR if an error is raised' do
      Zip::ZipFile.stub(:open).and_raise StandardError.new
      expect{@user.import_subscriptions @data_file}.to raise_error StandardError

      @user.data_import.status.should eq DataImport::ERROR
    end

    context 'unzipped opml file' do

      before :each do
        @uploaded_filename = File.join(File.dirname(__FILE__), '..', 'attachments', 'subscriptions.xml').to_s
        @data_file = File.open @uploaded_filename
      end

      it 'saves timestamped file in uploads folder' do
        Feedbunch::Application.config.uploads_manager.should_receive(:save).with @filename, @opml_data
        @user.import_subscriptions @data_file
      end

      it 'enqueues job to process the file' do
        Resque.should_receive(:enqueue).once.with ImportSubscriptionsJob, @filename, @user.id
        @user.import_subscriptions @data_file
      end
    end

    context 'zipped subscriptions.xml file' do

      before :each do
        @uploaded_filename = File.join(File.dirname(__FILE__), '..', 'attachments', 'feedbunch@gmail.com-takeout.zip').to_s
        @data_file = File.open @uploaded_filename
      end

      it 'saves timestamped file in uploads folder' do
        Feedbunch::Application.config.uploads_manager.should_receive(:save).with @filename, @opml_data
        @user.import_subscriptions @data_file
      end

      it 'enqueues job to process the file' do
        Resque.should_receive(:enqueue).once.with ImportSubscriptionsJob, @filename, @user.id
        @user.import_subscriptions @data_file
      end
    end

    context 'zipped opml file' do
      before :each do
        @uploaded_filename = File.join(File.dirname(__FILE__), '..', 'attachments', 'feedbunch@gmail.com-opml.zip').to_s
        @data_file = File.open @uploaded_filename
      end

      it 'saves timestamped file in uploads folder' do
        Feedbunch::Application.config.uploads_manager.should_receive(:save).with @filename, @opml_data
        @user.import_subscriptions @data_file
      end

      it 'enqueues job to process the file' do
        Resque.should_receive(:enqueue).once.with ImportSubscriptionsJob, @filename, @user.id
        @user.import_subscriptions @data_file
      end
    end

    context 'zipped xml file' do
      before :each do
        @uploaded_filename = File.join(File.dirname(__FILE__), '..', 'attachments', 'feedbunch@gmail.com-xml.zip').to_s
        @data_file = File.open @uploaded_filename
      end

      it 'saves timestamped file in uploads folder' do
        Feedbunch::Application.config.uploads_manager.should_receive(:save).with @filename, @opml_data
        @user.import_subscriptions @data_file
      end

      it 'enqueues job to process the file' do
        Resque.should_receive(:enqueue).once.with ImportSubscriptionsJob, @filename, @user.id
        @user.import_subscriptions @data_file
      end
    end
  end
end