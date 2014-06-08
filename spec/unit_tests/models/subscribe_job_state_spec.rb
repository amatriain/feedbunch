require 'rails_helper'

describe SubscribeJobState, type: :model do

  context 'validations' do

    it 'always belongs to a user' do
      subscribe_job_state = FactoryGirl.build :subscribe_job_state, user_id: nil
      expect(subscribe_job_state).not_to be_valid
    end

    it 'always belongs has a fetch_url' do
      subscribe_job_state = FactoryGirl.build :subscribe_job_state, fetch_url: nil
      expect(subscribe_job_state).not_to be_valid
    end

    it 'belongs to a feed if it has state SUCCESS' do
      subscribe_job_state = FactoryGirl.build :subscribe_job_state, feed_id: nil, state: SubscribeJobState::SUCCESS
      expect(subscribe_job_state).not_to be_valid

      feed = FactoryGirl.create :feed
      subscribe_job_state = FactoryGirl.build :subscribe_job_state, feed_id: feed.id, state: SubscribeJobState::SUCCESS
      expect(subscribe_job_state).to be_valid
    end

    it 'does not belong to a feed if it has state RUNNING' do
      feed = FactoryGirl.create :feed
      subscribe_job_state = FactoryGirl.build :subscribe_job_state, feed_id: feed.id, state: SubscribeJobState::RUNNING
      expect(subscribe_job_state).not_to be_valid

      subscribe_job_state = FactoryGirl.build :subscribe_job_state, feed_id: nil, state: SubscribeJobState::RUNNING
      expect(subscribe_job_state).to be_valid
    end

    it 'does not belong to a feed if it has state ERROR' do
      feed = FactoryGirl.create :feed
      subscribe_job_state = FactoryGirl.build :subscribe_job_state, feed_id: feed.id, state: SubscribeJobState::ERROR
      expect(subscribe_job_state).not_to be_valid

      subscribe_job_state = FactoryGirl.build :subscribe_job_state, feed_id: nil, state: SubscribeJobState::ERROR
      expect(subscribe_job_state).to be_valid
    end
  end

  context 'default values' do

    it 'defaults to state RUNNING when created' do
      subscribe_job_state = FactoryGirl.create :subscribe_job_state
      expect(subscribe_job_state.state).to eq RefreshFeedJobState::RUNNING
    end

  end

end
