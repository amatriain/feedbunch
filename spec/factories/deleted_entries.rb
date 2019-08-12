# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  sequence(:deleted_entry_guid_sequence) {|n| "some_entry_guid_#{n}"}
  sequence(:unique_hash_sequene){|n| "abcd123_#{n}"}

  factory :deleted_entry do
    guid {generate :deleted_entry_guid_sequence}
    unique_hash {generate :unique_hash_sequene}
    feed
  end
end
