# frozen_string_literal: true

require 'rails_helper'

describe User, type: :model do

  before :each do
    @user = FactoryBot.create :user
    @feed = FactoryBot.create :feed
    @user.subscribe @feed.fetch_url
    @old_refresh_feed_jobs_updated_at = @user.reload.refresh_feed_jobs_updated_at
  end

  context 'touches refresh feed jobs' do

    it 'when a job state is created' do
      job_state = FactoryBot.build :refresh_feed_job_state, user_id: @user.id, feed_id: @feed.id
      @user.refresh_feed_job_states << job_state
      expect(@user.reload.refresh_feed_jobs_updated_at).not_to eq @old_refresh_feed_jobs_updated_at
    end

    it 'when a job state is destroyed' do
      job_state = FactoryBot.build :refresh_feed_job_state, user_id: @user.id, feed_id: @feed.id
      @user.refresh_feed_job_states << job_state
      @old_refresh_feed_jobs_updated_at = @user.reload.refresh_feed_jobs_updated_at

      job_state.destroy
      expect(@user.reload.refresh_feed_jobs_updated_at).not_to eq @old_refresh_feed_jobs_updated_at
    end

    it 'when a job state is updated' do
      job_state = FactoryBot.build :refresh_feed_job_state, user_id: @user.id, feed_id: @feed.id
      @user.refresh_feed_job_states << job_state
      @old_refresh_feed_jobs_updated_at = @user.reload.refresh_feed_jobs_updated_at

      job_state.update state: RefreshFeedJobState::SUCCESS
      expect(@user.reload.refresh_feed_jobs_updated_at).not_to eq @old_refresh_feed_jobs_updated_at
    end
  end
end