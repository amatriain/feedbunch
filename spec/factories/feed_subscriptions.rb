# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :feed_subscription do
    user
    feed
    unread_entries {0}
  end
end