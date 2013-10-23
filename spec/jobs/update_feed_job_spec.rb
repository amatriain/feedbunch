require 'spec_helper'

describe UpdateFeedJob do

  before :each do
    @feed = FactoryGirl.create :feed
  end

  it 'updates feed when the job runs' do
    FeedClient.should_receive(:fetch).with @feed, anything

    UpdateFeedJob.perform @feed.id
  end

  it 'unschedules updates if the feed has been deleted when the job runs' do
    @feed.destroy
    UpdateFeedJob.should_receive(:unschedule_feed_updates).with @feed.id
    FeedClient.should_not_receive :fetch

    UpdateFeedJob.perform @feed.id
  end

  it 'does not update feed if it has been deleted' do
    FeedClient.should_not_receive :fetch
    @feed.destroy

    UpdateFeedJob.perform @feed.id
  end

  it 'programs a delayed job to start hourly updates' do
    Resque.should_receive(:enqueue_in) do |delay, job_class, args|
      delay.should be_between 0.minutes, 60.minutes
      job_class.should eq ScheduleFeedUpdatesJob
      args.should eq @feed.id
    end

    UpdateFeedJob.schedule_feed_updates @feed.id
  end

  it 'unschedules a job to update a feed' do
    Resque.should_receive(:remove_schedule).with "update_feed_#{@feed.id}"

    UpdateFeedJob.unschedule_feed_updates @feed.id
  end

  context 'cleanup old entries' do

    before :each do
      FeedClient.stub :fetch
      DateTime.stub(:now).and_return DateTime.new(2000, 1, 1)
    end

    it 'destroys entries older than a year' do
      old_entries = []
      (0..10).each do |i|
        old_entry = FactoryGirl.build :entry, feed_id: @feed.id, published: DateTime.new(1990, 1, 1+i)
        @feed.entries << old_entry
        old_entries << old_entry
      end

      UpdateFeedJob.perform @feed.id
      Entry.exists?(old_entries[0].id).should be_false
    end

    it 'keeps 10 entries per feed' do
      old_entries = []
      (0..10).each do |i|
        old_entry = FactoryGirl.build :entry, feed_id: @feed.id, published: DateTime.new(1990, 1, 1+i)
        @feed.entries << old_entry
        old_entries << old_entry
      end

      UpdateFeedJob.perform @feed.id
      (1..10).each do |i|
        Entry.exists?(old_entries[i].id).should be_true
      end
    end

    it 'does not destroy entries newer than a year' do
      entries = []
      (0..10).each do |i|
        entry = FactoryGirl.build :entry, feed_id: @feed.id, published: DateTime.new(1999, 1, 1+i)
        @feed.entries << entry
        entries << entry
      end

      UpdateFeedJob.perform @feed.id
      (0..10).each do |i|
        Entry.exists?(entries[i].id).should be_true
      end
    end

    it 'does not destroy entries if there are less than 10' do
      old_entries = []
      (0..5).each do |i|
        old_entry = FactoryGirl.build :entry, feed_id: @feed.id, published: DateTime.new(1990, 1, 1+i)
        @feed.entries << old_entry
        old_entries << old_entry
      end

      UpdateFeedJob.perform @feed.id
      (0..5).each do |i|
        Entry.exists?(old_entries[i].id).should be_true
      end
    end

  end

end