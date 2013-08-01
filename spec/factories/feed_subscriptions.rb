# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :feed_subscription do
    user
    feed
    unread_entries 0
  end
end