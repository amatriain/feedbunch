require 'rails_helper'

describe Feed, type: :model do

  before :each do
    @feed = FactoryGirl.create :feed
  end

  context 'validations' do
    it 'accepts valid URLs' do
      @feed.url = 'http://www.xkcd.com'
      expect(@feed.valid?).to be true
    end

    it 'does not accept invalid URLs' do
      old_url = @feed.url
      @feed.update url: 'invalid_url'
      expect(@feed.url).to eq old_url
    end

    it 'accepts an empty URL' do
      @feed.url = ''
      expect(@feed.valid?).to be true
      @feed.url = nil
      expect(@feed.valid?).to be true
    end

    it 'accepts duplicate URLs' do
      feed_dupe = FactoryGirl.build :feed, url: @feed.url
      expect(feed_dupe.valid?).to be true
    end

    it 'accepts valid fetch URLs' do
      @feed.fetch_url = 'http://www.xkcd.com/rss.xml'
      expect(@feed.valid?).to be true
    end

    it 'does not accept invalid fetch URLs' do
      old_fetch_url = @feed.fetch_url
      @feed.update fetch_url: 'invalid_url'
      expect(@feed.fetch_url).to eq old_fetch_url
    end

    it 'does not accept an empty fetch URL' do
      old_fetch_url = @feed.fetch_url
      @feed.update fetch_url: ''
      expect(@feed.fetch_url).to eq old_fetch_url
      @feed.update fetch_url: nil
      expect(@feed.fetch_url).to eq old_fetch_url
    end

    it 'does not accept duplicate fetch URLs' do
      feed_dupe = FactoryGirl.build :feed, fetch_url: @feed.fetch_url
      expect(feed_dupe.valid?).to be false
    end

    it 'does not accept an empty title' do
      @feed.title = ''
      expect(@feed.valid?).to be false
      @feed.title = nil
      expect(@feed.valid?).to be false
    end

  end

  context 'default values' do

    it 'takes a default fetch interval value of 3600 seconds' do
      feed = FactoryGirl.build :feed, fetch_interval_secs: nil
      feed.save!
      expect(feed.fetch_interval_secs).to eq 3600
    end

    it 'does not change the fetch interval if a value is passed' do
      feed = FactoryGirl.build :feed, fetch_interval_secs: 1800
      feed.save!
      expect(feed.fetch_interval_secs).to eq 1800
    end

    it 'marks feed as available by default' do
      feed = FactoryGirl.build :feed, available: nil
      feed.save!
      expect(feed.available).to be true
    end

    it 'uses the fetch_url as default for the url attribute if no url is specified' do
      fetch_url = 'http://some.fetch.url.com/'
      feed = FactoryGirl.build :feed, fetch_url: fetch_url, url: nil
      feed.save!
      expect(feed.url).to eq fetch_url
    end
  end

  context 'sanitization' do

    it 'sanitizes title' do
      unsanitized_title = '<script>alert("pwned!");</script>title'
      sanitized_title = 'title'
      feed = FactoryGirl.create :feed, title: unsanitized_title
      expect(feed.title).to eq sanitized_title
    end

    it 'sanitizes url' do
      unsanitized_url = 'http://xkcd.com<script>alert("pwned!");</script>'
      sanitized_url = 'http://xkcd.com/'
      feed = FactoryGirl.create :feed, url: unsanitized_url
      expect(feed.url).to eq sanitized_url
    end

    it 'sanitizes fetch url' do
      unsanitized_url = 'http://xkcd.com<script>alert("pwned!");</script>'
      sanitized_url = 'http://xkcd.com/'
      feed = FactoryGirl.create :feed, fetch_url: unsanitized_url
      expect(feed.fetch_url).to eq sanitized_url
    end

  end

  context 'trimming' do

    it 'trims title' do
      untrimmed_title = "\n      title"
      trimmed_title = 'title'
      feed = FactoryGirl.create :feed, title: untrimmed_title
      expect(feed.title).to eq trimmed_title
    end

    it 'trims url' do
      untrimmed_url = "\n    http://xkcd.com"
      trimmed_url = 'http://xkcd.com/'
      feed = FactoryGirl.create :feed, url: untrimmed_url
      expect(feed.url).to eq trimmed_url
    end

    it 'trims fetch url' do
      untrimmed_url = "\n    http://xkcd.com"
      trimmed_url = 'http://xkcd.com/'
      feed = FactoryGirl.create :feed, fetch_url: untrimmed_url
      expect(feed.fetch_url).to eq trimmed_url
    end
  end

  context 'convert to utf-8' do
    it 'converts title' do
      # 0xE8 is a valid character in ISO-8859-1, invalid in UTF-8
      not_utf8_title = "\xE8 title"
      utf8_title = 'è title'
      feed = FactoryGirl.create :feed, title: not_utf8_title
      expect(feed.title).to eq utf8_title
    end

    it 'converts url' do
      # 0xE8 is a valid character in ISO-8859-1, invalid in UTF-8
      not_utf8_url = "http://xkcd.com/\xE8"
      utf8_url = 'http://xkcd.com/%C3%A8'
      feed = FactoryGirl.create :feed, url: not_utf8_url
      expect(feed.url).to eq utf8_url
    end

    it 'converts fetch url' do
      # 0xE8 is a valid character in ISO-8859-1, invalid in UTF-8
      not_utf8_url = "http://xkcd.com/\xE8"
      utf8_url = 'http://xkcd.com/%C3%A8'
      feed = FactoryGirl.create :feed, fetch_url: not_utf8_url
      expect(feed.fetch_url).to eq utf8_url
    end
  end

  context 'url percent-encoding' do

    it 'encodes invalid characters in url' do
      not_encoded_url = 'https://www.google.es/search?q=año'
      encoded_url = 'https://www.google.es/search?q=a%C3%B1o'
      feed = FactoryGirl.create :feed, url: not_encoded_url
      expect(feed.url).to eq encoded_url
    end

    it 'does not change already encoded url' do
      encoded_url = 'https://www.google.es/search?q=a%C3%B1o'
      feed = FactoryGirl.create :feed, url: encoded_url
      expect(feed.url).to eq encoded_url
    end

    it 'encodes invalid characters in fetch_url' do
      not_encoded_url = 'https://www.google.es/search?q=año'
      encoded_url = 'https://www.google.es/search?q=a%C3%B1o'
      feed = FactoryGirl.create :feed, fetch_url: not_encoded_url
      expect(feed.fetch_url).to eq encoded_url
    end

    it 'does not change already encoded fetch_url' do
      encoded_url = 'https://www.google.es/search?q=a%C3%B1o'
      feed = FactoryGirl.create :feed, fetch_url: encoded_url
      expect(feed.fetch_url).to eq encoded_url
    end
  end

  context 'association with entries' do
    it 'destroys entries when destroying a feed' do
      entry1 = FactoryGirl.build :entry, feed_id: @feed.id
      entry2 = FactoryGirl.build :entry, feed_id: @feed.id
      @feed.entries << entry1 << entry2

      expect(Entry.count).to eq 2

      @feed.destroy

      expect(Entry.count).to eq 0
    end

    it 'does not allow the same entry more than once' do
      entry = FactoryGirl.build :entry, feed_id: @feed.id
      @feed.entries << entry
      @feed.entries << entry

      expect(@feed.entries.count).to eq 1
      expect(@feed.entries.where(id: entry.id).count).to eq 1
    end
  end

  context 'association with deleted_entries' do
    it 'destroys deleted_entries when destroying a feed' do
      deleted_entry1 = FactoryGirl.build :deleted_entry, feed_id: @feed.id
      deleted_entry2 = FactoryGirl.build :deleted_entry, feed_id: @feed.id
      @feed.deleted_entries << deleted_entry1 << deleted_entry2

      expect(DeletedEntry.count).to eq 2

      @feed.destroy

      expect(DeletedEntry.count).to eq 0
    end
  end

  context 'user suscriptions' do
    before :each do
      @user1 = FactoryGirl.create :user
      @user2 = FactoryGirl.create :user
      @user3 = FactoryGirl.create :user
      @user1.subscribe @feed.fetch_url
      @user2.subscribe @feed.fetch_url
    end

    it 'returns user suscribed to the feed' do
      expect(@feed.users).to include @user1
      expect(@feed.users).to include @user2
    end

    it 'does not return users not suscribed to the feed' do
      expect(@feed.users).not_to include @user3
    end

    it 'does not allow subscribing the same user more than once' do
      expect(@feed.users.count).to eq 2
      expect(@feed.users.where(id: @user1.id).count).to eq 1

      expect {@user1.subscribe @feed.fetch_url}.to raise_error
      expect(@feed.users.count).to eq 2
      expect(@feed.users.where(id: @user1.id).count).to eq 1
    end
  end

  context 'association with folders' do
    before :each do
      @folder1 = FactoryGirl.build :folder
      @folder2 = FactoryGirl.build :folder
      @folder3 = FactoryGirl.create :folder
      @feed.folders << @folder1 << @folder2
    end

    it 'returns folders to which this feed is associated' do
      expect(@feed.folders).to include @folder1
      expect(@feed.folders).to include @folder2
    end

    it 'does not return folders to which this feed is not associated' do
      expect(@feed.folders).not_to include @folder3
    end

    it 'does not allow associating with the same folder more than once' do
      expect(@feed.folders.count).to eq 2
      expect(@feed.folders.where(id: @folder1.id).count).to eq 1

      @feed.folders << @folder1
      expect(@feed.folders.count).to eq 2
      expect(@feed.folders.where(id: @folder1.id).count).to eq 1
    end

    it 'allows associating with at most one folder for a single user' do
      user = FactoryGirl.create :user
      folder1 = FactoryGirl.build :folder, user_id: user.id
      folder2 = FactoryGirl.build :folder, user_id: user.id
      user.folders << folder1 << folder2

      @feed.folders << folder1
      @feed.folders << folder2

      expect(@feed.folders).to include folder1
      expect(@feed.folders).not_to include folder2
    end

    it 'returns the folder to which a feed belongs, given a user id' do
      user = FactoryGirl.create :user
      folder = FactoryGirl.build :folder, user_id: user.id
      user.folders << folder
      user.subscribe @feed.fetch_url
      folder.feeds << @feed

      expect(@feed.user_folder(user)).to eq folder
    end

    it 'returns nil if the feed belongs to no folder for that user' do
      user = FactoryGirl.create :user
      user.subscribe @feed.fetch_url
      expect(@feed.user_folder(user)).to be_nil
    end
  end

  context 'association with refresh_feed_job_states' do

    before :each do
      @refresh_feed_job_state_1 = FactoryGirl.build :refresh_feed_job_state, feed_id: @feed.id
      @refresh_feed_job_state_2 = FactoryGirl.build :refresh_feed_job_state, feed_id: @feed.id
      @refresh_feed_job_state_3 = FactoryGirl.create :refresh_feed_job_state
      @feed.refresh_feed_job_states << @refresh_feed_job_state_1 << @refresh_feed_job_state_2
    end

    it 'returns refresh_feed_job_states associated with this feed' do
      expect(@feed.refresh_feed_job_states).to include @refresh_feed_job_state_1
      expect(@feed.refresh_feed_job_states).to include @refresh_feed_job_state_2
    end

    it 'does not return refresh_feed_job_states not associated with this feed' do
      expect(@feed.refresh_feed_job_states).not_to include @refresh_feed_job_state_3
    end

    it 'deletes refresh_feed_job_states when deleting a feed' do
      expect(RefreshFeedJobState.count).to eq 3
      @feed.destroy
      expect(RefreshFeedJobState.count).to eq 1
      expect(RefreshFeedJobState.all).not_to include @refresh_feed_job_state_1
      expect(RefreshFeedJobState.all).not_to include @refresh_feed_job_state_2
      expect(RefreshFeedJobState.all).to include @refresh_feed_job_state_3
    end
  end

  context 'association with subscribe_feed_states' do

    before :each do
      @subscribe_job_state_1 = FactoryGirl.build :subscribe_job_state, feed_id: @feed.id, state: SubscribeJobState::SUCCESS
      @subscribe_job_state_2 = FactoryGirl.build :subscribe_job_state, feed_id: @feed.id, state: SubscribeJobState::SUCCESS
      @subscribe_job_state_3 = FactoryGirl.create :subscribe_job_state, state: SubscribeJobState::SUCCESS
      @feed.subscribe_job_states << @subscribe_job_state_1 << @subscribe_job_state_2
    end

    it 'returns subscribe job states associated with this feed' do
      expect(@feed.subscribe_job_states).to include @subscribe_job_state_1
      expect(@feed.subscribe_job_states).to include @subscribe_job_state_2
    end

    it 'does not return subscribe job states not associated with this feed' do
      expect(@feed.subscribe_job_states).not_to include @subscribe_job_state_3
    end

    it 'deletes subscribe_job_states when deleting a feed' do
      expect(SubscribeJobState.count).to eq 3
      @feed.destroy
      expect(SubscribeJobState.count).to eq 1
      expect(SubscribeJobState.all).to include @subscribe_job_state_3
    end

  end

  context 'scheduled updates' do

    it 'schedules next update for a feed when it is created' do
      feed = FactoryGirl.build :feed
      expect(ScheduledUpdateFeedWorker).to receive(:perform_in).once do |seconds, feed_id|
        expect(seconds).to be_between 0.minutes, 60.minutes
        expect(feed_id).to eq feed.id
      end
      feed.save
    end

    it 'does not change scheduling when saving an already existing feed' do
      expect(ScheduledUpdateFeedWorker).not_to receive :perform_in
      expect(ScheduledUpdateFeedWorker).not_to receive :perform_at
      @feed.title = 'another title'
      @feed.save
    end

    it 'unschedules updates for a feed when destroying it' do
      job = double 'job', klass: 'ScheduledUpdateFeedWorker', args: [@feed.id]
      allow(Sidekiq::ScheduledSet).to receive(:new).and_return [job]
      expect(job).to receive(:delete).once
      @feed.destroy
    end

    it 'does not unschedule updates for other feeds when destroying a feed' do
      feed2 = FactoryGirl.create :feed
      job = double 'job', klass: 'ScheduledUpdateFeedWorker', args: [feed2.id]
      allow(Sidekiq::ScheduledSet).to receive(:new).and_return [job]
      expect(job).not_to receive :delete
      @feed.destroy
    end

    it 'does not unschedule other jobs when destroying a feed' do
      job = double 'job', klass: 'AnotherWorker', args: [@feed.id]
      allow(Sidekiq::ScheduledSet).to receive(:new).and_return [job]
      expect(job).not_to receive :delete
      @feed.destroy
    end

    it 'unschedules updates for a feed when it is marked as unavailable' do
      job = double 'job', klass: 'ScheduledUpdateFeedWorker', args: [@feed.id]
      allow(Sidekiq::ScheduledSet).to receive(:new).and_return [job]
      expect(job).to receive(:delete).once
      @feed.update available: false
    end

    it 'does not unschedule updates for a feed when it is marked as available' do
      @feed.update_column :available, false
      job = double 'job', klass: 'ScheduledUpdateFeedWorker', args: [@feed.id]
      allow(Sidekiq::ScheduledSet).to receive(:new).and_return [job]
      expect(job).not_to receive :delete
      @feed.update available: true
    end

    it 'does not unschedule updates for a feed when the available attribute is not changed' do
      job = double 'job', klass: 'ScheduledUpdateFeedWorker', args: [@feed.id]
      allow(Sidekiq::ScheduledSet).to receive(:new).and_return [job]
      expect(job).not_to receive :delete
      @feed.update title: 'some other title'
    end
  end

  context 'url blacklist' do

    before :each do
      @blacklisted_url = 'some.aede.bastard.com'
      @blacklisted_host = Addressable::URI.parse("http://#{@blacklisted_url}").host
      Rails.application.config.hosts_blacklist = [@blacklisted_host]
    end

    it 'does not raise an error if feed is not blacklisted' do
      feed_2 = FactoryGirl.build :feed, url: 'http://some.url', fetch_url: 'http://another.url'
      expect{feed_2.save}.not_to raise_error
    end

    context 'blacklisted url' do

      it 'raises an error when trying to create a feed with blacklisted url' do
        feed_2 = FactoryGirl.build :feed, url: "http://#{@blacklisted_url}"
        expect{feed_2.save}.to raise_error BlacklistedUrlError
      end

      it 'raises an error when trying to create a feed with internationalized blacklisted url' do
        blacklisted_url = 'http://www.gewürzrevolver.de'
        normalized_url = Addressable::URI.parse(blacklisted_url).normalize
        blacklisted_host = normalized_url.host
        Rails.application.config.hosts_blacklist = [blacklisted_host]

        feed_2 = FactoryGirl.build :feed, url: blacklisted_url
        expect{feed_2.save}.to raise_error BlacklistedUrlError
      end

      it 'raises an error when trying to update a feed with a blacklisted url' do
        feed_2 = FactoryGirl.create :feed, url: 'http://some.url'
        expect{feed_2.update url: "http://#{@blacklisted_url}"}.to raise_error BlacklistedUrlError
      end

      it 'raises an error when trying to save a feed with url = subpath of a blacklisted url' do
        feed_2 = FactoryGirl.build :feed, url: "http://#{@blacklisted_url}/feed.php"
        expect{feed_2.save}.to raise_error BlacklistedUrlError
      end

      it 'raises an error when trying to save a feed with url = subdomain of a blacklisted url' do
        feed_2 = FactoryGirl.build :feed, url: "http://subdomain.#{@blacklisted_url}"
        expect{feed_2.save}.to raise_error BlacklistedUrlError
      end

      it 'raises an error when trying to save a feed with url = subpath and subdomain of a blacklisted url' do
        feed_2 = FactoryGirl.build :feed, url: "http://subdomain.#{@blacklisted_url}/feed.php"
        expect{feed_2.save}.to raise_error BlacklistedUrlError
      end

      it 'does not raise error if url host is substring but not subdomain of a blacklisted url' do
        feed_2 = FactoryGirl.build :feed, url: "http://substring#{@blacklisted_url}/feed.php"
        expect{feed_2.save}.not_to raise_error
      end
    end

    context 'blacklisted fetch_url' do

      it 'raises an error when trying to create a feed with blacklisted fetch_url' do
        feed_2 = FactoryGirl.build :feed, fetch_url: "http://#{@blacklisted_url}"
        expect{feed_2.save}.to raise_error BlacklistedUrlError
      end

      it 'raises an error when trying to create a feed with internationalized blacklisted fetch_url' do
        blacklisted_url = 'http://www.gewürzrevolver.de'
        normalized_url = Addressable::URI.parse(blacklisted_url).normalize
        blacklisted_host = normalized_url.host
        Rails.application.config.hosts_blacklist = [blacklisted_host]

        feed_2 = FactoryGirl.build :feed, fetch_url: blacklisted_url
        expect{feed_2.save}.to raise_error BlacklistedUrlError
      end

      it 'raises an error when trying to update a feed with a blacklisted fetch_url' do
        feed_2 = FactoryGirl.create :feed, fetch_url: 'http://some.url'
        expect{feed_2.update fetch_url: "http://#{@blacklisted_url}"}.to raise_error BlacklistedUrlError
      end

      it 'raises an error when trying to save a feed with fetch_url = subpath of a blacklisted url' do
        feed_2 = FactoryGirl.create :feed, fetch_url: 'http://some.url'
        expect{feed_2.update fetch_url: "http://#{@blacklisted_url}/feed.php"}.to raise_error BlacklistedUrlError
      end

      it 'raises an error when trying to save a feed with fetch_url = subdomain of a blacklisted url' do
        feed_2 = FactoryGirl.create :feed, fetch_url: 'http://some.url'
        expect{feed_2.update fetch_url: "http://subdomain.#{@blacklisted_url}"}.to raise_error BlacklistedUrlError
      end

      it 'raises an error when trying to save a feed with fetch_url = subpath and subdomain of a blacklisted url' do
        feed_2 = FactoryGirl.create :feed, fetch_url: 'http://some.url'
        expect{feed_2.update fetch_url: "http://subdomain.#{@blacklisted_url}/feed.php"}.to raise_error BlacklistedUrlError
      end

      it 'does not raise error if fetch_url host is substring but not subdomain of a blacklisted url'  do
        feed_2 = FactoryGirl.build :feed, fetch_url: "http://substring#{@blacklisted_url}/feed.php"
        expect{feed_2.save}.not_to raise_error
      end
    end

  end
end

