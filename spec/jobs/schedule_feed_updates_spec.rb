require 'spec_helper'

describe ScheduleFeedUpdatesJob do

  before :each do
    @feed = FactoryGirl.create :feed
  end

  it 'immediately enqueues a feed update' do
    Resque.should_receive(:enqueue).with UpdateFeedJob, @feed.id
    ScheduleFeedUpdatesJob.perform @feed.id
  end

  it 'schedules hourly feed updates' do
    Resque.should_receive(:set_schedule) do |name, config|
      name.should eq "update_feed_#{@feed.id}"
      config[:class].should eq 'UpdateFeedJob'
      config[:args].should eq @feed.id
      config[:every].should eq '1h'
    end

    ScheduleFeedUpdatesJob.perform @feed.id
  end

  it 'does not schedule updates if the feed has been deleted' do
    Resque.should_not_receive :set_schedule
    @feed.destroy

    ScheduleFeedUpdatesJob.perform @feed.id
  end
end