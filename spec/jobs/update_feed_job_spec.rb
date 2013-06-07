require 'spec_helper'

describe UpdateFeedJob do

  before :each do
    @feed = FactoryGirl.create :feed

    # Ensure no HTTP calls are made
    RestClient.stub :get
  end

  it 'updates feed when the job runs' do
    FeedClient.should_receive(:fetch).with @feed.id

    UpdateFeedJob.perform @feed.id
  end
end