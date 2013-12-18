require 'spec_helper'

describe Feed do

  before :each do
    @feed = FactoryGirl.create :feed
  end

  context 'validations' do
    it 'accepts valid URLs' do
      @feed.url = 'http://www.xkcd.com'
      @feed.valid?.should be_true
    end

    it 'does not accept invalid URLs' do
      old_url = @feed.url
      @feed.update url: 'invalid_url'
      @feed.url.should eq old_url
    end

    it 'accepts an empty URL' do
      @feed.url = ''
      @feed.valid?.should be_true
      @feed.url = nil
      @feed.valid?.should be_true
    end

    it 'accepts duplicate URLs' do
      feed_dupe = FactoryGirl.build :feed, url: @feed.url
      feed_dupe.valid?.should be_true
    end

    it 'accepts valid fetch URLs' do
      @feed.fetch_url = 'http://www.xkcd.com/rss.xml'
      @feed.valid?.should be_true
    end

    it 'does not accept invalid fetch URLs' do
      old_fetch_url = @feed.fetch_url
      @feed.update fetch_url: 'invalid_url'
      @feed.fetch_url.should eq old_fetch_url
    end

    it 'does not accept an empty fetch URL' do
      old_fetch_url = @feed.fetch_url
      @feed.update fetch_url: ''
      @feed.fetch_url.should eq old_fetch_url
      @feed.update fetch_url: nil
      @feed.fetch_url.should eq old_fetch_url
    end

    it 'does not accept duplicate fetch URLs' do
      feed_dupe = FactoryGirl.build :feed, fetch_url: @feed.fetch_url
      feed_dupe.valid?.should be_false
    end

    it 'does not accept an empty title' do
      @feed.title = ''
      @feed.valid?.should be_false
      @feed.title = nil
      @feed.valid?.should be_false
    end


  end

  context 'sanitization' do

    it 'sanitizes title' do
      unsanitized_title = '<script>alert("pwned!");</script>title'
      sanitized_title = 'title'
      feed = FactoryGirl.create :feed, title: unsanitized_title
      feed.title.should eq sanitized_title
    end

    it 'sanitizes url' do
      unsanitized_url = "http://xkcd.com<script>alert('pwned!');</script>"
      sanitized_url = 'http://xkcd.com'
      feed = FactoryGirl.create :feed, url: unsanitized_url
      feed.url.should eq sanitized_url
    end

    it 'sanitizes fetch url' do
      unsanitized_url = "http://xkcd.com<script>alert('pwned!');</script>"
      sanitized_url = 'http://xkcd.com'
      feed = FactoryGirl.create :feed, fetch_url: unsanitized_url
      feed.fetch_url.should eq sanitized_url
    end

  end

  context 'trimming' do

    it 'trims title' do
      untrimmed_title = "\n      title"
      trimmed_title = 'title'
      feed = FactoryGirl.create :feed, title: untrimmed_title
      feed.title.should eq trimmed_title
    end

    it 'trims url' do
      untrimmed_url = "\n    http://xkcd.com"
      trimmed_url = 'http://xkcd.com'
      feed = FactoryGirl.create :feed, url: untrimmed_url
      feed.url.should eq trimmed_url
    end

    it 'trims fetch url' do
      untrimmed_url = "\n    http://xkcd.com"
      trimmed_url = 'http://xkcd.com'
      feed = FactoryGirl.create :feed, fetch_url: untrimmed_url
      feed.fetch_url.should eq trimmed_url
    end
  end

  context 'feed entries' do
    it 'deletes entries when deleting a feed' do
      entry1 = FactoryGirl.build :entry
      entry2 = FactoryGirl.build :entry
      @feed.entries << entry1 << entry2

      Entry.count.should eq 2

      @feed.destroy
      Entry.count.should eq 0
    end

    it 'does not allow the same entry more than once' do
      entry = FactoryGirl.build :entry, feed_id: @feed.id
      @feed.entries << entry
      @feed.entries << entry

      @feed.entries.count.should eq 1
      @feed.entries.where(id: entry.id).count.should eq 1
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
      @feed.users.should include @user1
      @feed.users.should include @user2
    end

    it 'does not return users not suscribed to the feed' do
      @feed.users.should_not include @user3
    end

    it 'does not allow subscribing the same user more than once' do
      @feed.users.count.should eq 2
      @feed.users.where(id: @user1.id).count.should eq 1

      expect {@user1.subscribe @feed.fetch_url}.to raise_error
      @feed.users.count.should eq 2
      @feed.users.where(id: @user1.id).count.should eq 1
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
      @feed.folders.should include @folder1
      @feed.folders.should include @folder2
    end

    it 'does not return folders to which this feed is not associated' do
      @feed.folders.should_not include @folder3
    end

    it 'does not allow associating with the same folder more than once' do
      @feed.folders.count.should eq 2
      @feed.folders.where(id: @folder1.id).count.should eq 1

      @feed.folders << @folder1
      @feed.folders.count.should eq 2
      @feed.folders.where(id: @folder1.id).count.should eq 1
    end

    it 'allows associating with at most one folder for a single user' do
      user = FactoryGirl.create :user
      folder1 = FactoryGirl.build :folder, user_id: user.id
      folder2 = FactoryGirl.build :folder, user_id: user.id
      user.folders << folder1 << folder2

      @feed.folders << folder1
      @feed.folders << folder2

      @feed.folders.should include folder1
      @feed.folders.should_not include folder2
    end

    it 'returns the folder to which a feed belongs, given a user id' do
      user = FactoryGirl.create :user
      folder = FactoryGirl.build :folder, user_id: user.id
      user.folders << folder
      user.subscribe @feed.fetch_url
      folder.feeds << @feed

      @feed.user_folder(user).should eq folder
    end

    it 'returns nil if the feed belongs to no folder for that user' do
      user = FactoryGirl.create :user
      user.subscribe @feed.fetch_url
      @feed.user_folder(user).should be_nil
    end
  end

  context 'scheduled updates' do

    it 'schedules updates for a feed when it is created' do
      feed = FactoryGirl.build :feed
      UpdateFeedJob.should_receive :schedule_feed_updates do |feed_id|
        f = Feed.find feed_id
        f.should eq feed.reload
      end
      feed.save
    end

    it 'does not change scheduling when saving an already existing feed' do
      UpdateFeedJob.should_not_receive :schedule_feed_updates
      @feed.title = 'another title'
      @feed.save
    end

    it 'unschedules updates for a feed when it is destroyed' do
      UpdateFeedJob.should_receive(:unschedule_feed_updates).with @feed.id
      @feed.destroy
    end
  end
end
