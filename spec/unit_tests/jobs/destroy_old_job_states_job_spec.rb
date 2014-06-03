require 'spec_helper'

describe DestroyOldJobStatesJob do

  before :each do
    date = Time.zone.parse '2000-01-01'
    date_old = date - (24.hours + 1.minute)
    date_not_old = date - 1.hour
    ActiveSupport::TimeZone.any_instance.stub(:now).and_return date

    @user = FactoryGirl.create :user
    @feed1 = FactoryGirl.create :feed
    @feed2 = FactoryGirl.create :feed

    @user.subscribe @feed1.fetch_url
    @user.subscribe @feed2.fetch_url

    @subscribe_job_state_1 = FactoryGirl.build :subscribe_job_state, user_id: @user.id, fetch_url: @feed1.fetch_url
    @subscribe_job_state_2 = FactoryGirl.build :subscribe_job_state, user_id: @user.id, fetch_url: @feed2.fetch_url
    @user.subscribe_job_states << @subscribe_job_state_1 << @subscribe_job_state_2
    @subscribe_job_state_1.update created_at: date_old
    @subscribe_job_state_2.update created_at: date_not_old

    @refresh_feed_job_state_1 = FactoryGirl.build :refresh_feed_job_state, user_id: @user.id, feed_id: @feed1.id
    @refresh_feed_job_state_2 = FactoryGirl.build :refresh_feed_job_state, user_id: @user.id, feed_id: @feed2.id
    @user.refresh_feed_job_states << @refresh_feed_job_state_1 << @refresh_feed_job_state_2
    @refresh_feed_job_state_1.update created_at: date_old
    @refresh_feed_job_state_2.update created_at: date_not_old
  end

  it 'destroys old states' do
    DestroyOldJobStatesJob.perform
    SubscribeJobState.exists?(@subscribe_job_state_1.id).should be false
    RefreshFeedJobState.exists?(@refresh_feed_job_state_1.id).should be false
  end

  it 'does not destroy newer states' do
    DestroyOldJobStatesJob.perform
    SubscribeJobState.exists?(@subscribe_job_state_2.id).should be_true
    RefreshFeedJobState.exists?(@refresh_feed_job_state_2.id).should be_true
  end

end