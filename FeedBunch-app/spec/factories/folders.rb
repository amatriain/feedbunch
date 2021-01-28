# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  sequence(:folder_title_sequence) {|n| "some_folder_title_#{n}"}

  factory :folder do
    title {generate :folder_title_sequence}
    user
    subscriptions_updated_at {Time.zone.now}
  end
end
