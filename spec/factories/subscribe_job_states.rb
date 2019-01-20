# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  sequence(:fetch_url_sequence) {|n| "http://some.feed.com/feed/#{n}"}

  factory :subscribe_job_state do
    state {'RUNNING'}
    user
    fetch_url {generate :fetch_url_sequence}
    feed {(state=='SUCCESS')?FactoryBot.create(:feed):nil}
  end
end
