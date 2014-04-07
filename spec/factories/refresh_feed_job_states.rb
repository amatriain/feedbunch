# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :refresh_feed_job_state do
    state 'RUNNING'
    user
    feed
  end
end
