require 'rails_helper'

describe FixSchedulesWorker do

  before :each do
    @feed = FactoryGirl.create :feed

    # @feed has a scheduled update
    @job = double 'job', klass: 'ScheduledUpdateFeedWorker', args: [@feed.id]
    allow(Sidekiq::ScheduledSet).to receive(:new).and_return [@job]
  end

  it 'adds missing scheduled feed updates' do
    feed_unscheduled = FactoryGirl.create :feed
    # @feed has a scheduled update, feed_unscheduled does not

    expect(ScheduledUpdateFeedWorker).to receive(:perform_at).once do |perform_time, feed_id|
      # Scheduled time should be in the next hour
      expect(perform_time - Time.zone.now).to be_between 0.minutes, 60.minutes
      expect(feed_id).to eq feed_unscheduled.id
    end

    FixSchedulesWorker.new.perform
  end

  it 'schedules next update when it should have been scheduled' do
    @feed.update last_fetched: Time.zone.parse('2000-01-01 01:00:00')
    @feed.update fetch_interval_secs: 12.hours

    time_now = Time.zone.parse('2000-01-01 10:00:00')
    allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return time_now
    allow(Resque).to receive :fetch_schedule

    # TODO rework this after migrating from resque-scheduler to a system that supports Sidekiq
    # A job to schedule updates for @feed should be enqueued to be run at 2000-01-01 13:00:00
    expect(Resque).to receive(:set_schedule).once do |name, config|
      expect(name).to eq "update_feed_#{@feed.id}"
      expect(config[:class]).to eq 'ScheduledUpdateFeedJob'
      expect(config[:args]).to eq @feed.id
      expect(config[:every][0]).to eq "#{12.hours}s"
      expect(config[:every][1][:first_in]).to eq 3.hours
    end

    FixSchedulesWorker.new.perform
  end

  it 'immediately schedules next update if the next update should have been scheduled in the past' do
    @feed.update last_fetched: Time.zone.parse('2000-01-01 01:00:00')
    @feed.update fetch_interval_secs: 12.hours

    time_now = Time.zone.parse('2000-01-02 01:00:00')
    allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return time_now
    allow(Resque).to receive :fetch_schedule

    # TODO rework this after migrating from resque-scheduler to a system that supports Sidekiq
    # A job to schedule updates for @feed should be enqueued to be run immediately
    expect(Resque).to receive(:set_schedule).once do |name, config|
      expect(name).to eq "update_feed_#{@feed.id}"
      expect(config[:class]).to eq 'ScheduledUpdateFeedJob'
      expect(config[:args]).to eq @feed.id
      expect(config[:every][0]).to eq "#{12.hours}s"
      expect(config[:every][1][:first_in]).to be_between 0.minutes, 15.minutes
    end

    FixSchedulesWorker.new.perform
  end

  it 'schedules next update in the following hour if feed has never been updated' do
    allow(Resque).to receive :fetch_schedule

    # TODO rework this after migrating from resque-scheduler to a system that supports Sidekiq
    # A job to schedule updates for @feed should be scheduled sometime during the next hour
    expect(Resque).to receive(:set_schedule).once do |name, config|
      expect(name).to eq "update_feed_#{@feed.id}"
      expect(config[:class]).to eq 'ScheduledUpdateFeedJob'
      expect(config[:args]).to eq @feed.id
      expect(config[:every][0]).to eq "#{1.hour}s"
      expect(config[:every][1][:first_in]).to be_between 0.minutes, 60.minutes
    end

    expect(@feed.last_fetched).to be_nil
    FixSchedulesWorker.new.perform
  end

  it 'does nothing for existing feed updates' do
    feed_scheduled = FactoryGirl.create :feed
    # @feed and feed_scheduled have scheduled updates

    # TODO rework this after migrating from resque-scheduler to a system that supports Sidekiq
    allow(Resque).to receive :fetch_schedule do |name|
      if name == "update_feed_#{@feed.id}"
        {"class"=>"ScheduledUpdateFeedJob", "args"=>@feed.id, "every"=>"1h"}
      elsif name == "update_feed_#{feed_scheduled.id}"
        {"class"=>"ScheduledUpdateFeedJob", "args"=>feed_scheduled.id, "every"=>"1h"}
      end
    end

    # TODO rework this after migrating from resque-scheduler to a system that supports Sidekiq
    # No job to schedule updates should be enqueued
    expect(Resque).not_to receive :set_schedule

    FixSchedulesWorker.new.perform
  end

  it 'does not add a schedule for an unavailable feed' do
    @feed.update available: false
    allow(Resque).to receive :fetch_schedule

    expect(Resque).not_to receive :set_schedule

    FixSchedulesWorker.new.perform
  end
end