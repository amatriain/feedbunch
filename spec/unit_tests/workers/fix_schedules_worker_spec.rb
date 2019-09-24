# frozen_string_literal: true

require 'rails_helper'

describe FixSchedulesWorker do

  before :each do
    @feed = FactoryBot.create :feed

    # @feed has a scheduled update
    @job = double 'job', klass: 'ScheduledUpdateFeedWorker', args: [@feed.id]
    allow(Sidekiq::ScheduledSet).to receive(:new).and_return [@job]
  end

  it 'adds missing scheduled feed updates' do
    feed_unscheduled = FactoryBot.create :feed
    # @feed has a scheduled update, feed_unscheduled does not

    expect(ScheduledUpdateFeedWorker).to receive(:perform_at).once do |perform_time, feed_id|
      # Scheduled time should be in the next hour
      expect(perform_time - Time.zone.now).to be_between (0.minutes - 1.second), (60.minutes + 1.second)
      expect(feed_id).to eq feed_unscheduled.id
    end

    FixSchedulesWorker.new.perform
  end

  it 'schedules next update when it should have been scheduled' do
    last_update = Time.zone.parse '3000-01-01 01:00:00'
    @feed.update last_fetched: last_update
    interval = 12.hours
    @feed.update fetch_interval_secs: interval
    # No scheduled update set for @feed
    allow(Sidekiq::ScheduledSet).to receive(:new).and_return []

    expect(ScheduledUpdateFeedWorker).to receive(:perform_at).once do |perform_time, feed_id|
      # Scheduled time should be 12 hours after last update
      expect(perform_time).to eq last_update + interval
      expect(feed_id).to eq @feed.id
    end

    FixSchedulesWorker.new.perform
  end

  it 'schedules next update in the following hour if feed has never been updated' do
    @feed.update last_fetched: nil
    # No scheduled update set for @feed
    allow(Sidekiq::ScheduledSet).to receive(:new).and_return []

    expect(ScheduledUpdateFeedWorker).to receive(:perform_at).once do |perform_time, feed_id|
      # Scheduled time should be in the next hour
      # Give 1 additional minute on each end to the interval, to get rid of precision errors.
      expect(perform_time).to be_between (Time.zone.now - 1.minute), (Time.zone.now + 1.hour + 1.minute)
      expect(feed_id).to eq @feed.id
    end

    FixSchedulesWorker.new.perform
  end

  it 'does nothing for existing feed updates' do
    expect(ScheduledUpdateFeedWorker).not_to receive :perform_at
    expect(ScheduledUpdateFeedWorker).not_to receive :perform_in
    expect(@job).not_to receive :delete
    FixSchedulesWorker.new.perform
  end

  it 'does not add a schedule for an unavailable feed' do
    # No scheduled update set for @feed
    allow(Sidekiq::ScheduledSet).to receive(:new).and_return []
    @feed.update available: false

    expect(ScheduledUpdateFeedWorker).not_to receive :perform_at
    expect(ScheduledUpdateFeedWorker).not_to receive :perform_in

    FixSchedulesWorker.new.perform
  end
end