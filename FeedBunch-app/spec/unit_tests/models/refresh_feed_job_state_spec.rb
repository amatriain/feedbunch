# frozen_string_literal: true

require 'rails_helper'

describe RefreshFeedJobState, type: :model do

  context 'validations' do

    it 'always belongs to a user' do
      refresh_feed_job_state = FactoryBot.build :refresh_feed_job_state, user_id: nil
      expect(refresh_feed_job_state).not_to be_valid
    end

    it 'always belongs to a feed' do
      refresh_feed_job_state = FactoryBot.build :refresh_feed_job_state, feed_id: nil
      expect(refresh_feed_job_state).not_to be_valid
    end
  end

  context 'default values' do

    it 'defaults to state RUNNING when created' do
      refresh_feed_job_state = FactoryBot.create :refresh_feed_job_state
      expect(refresh_feed_job_state.state).to eq RefreshFeedJobState::RUNNING
    end

  end

end
