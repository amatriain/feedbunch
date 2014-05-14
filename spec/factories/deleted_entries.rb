# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence(:deleted_entry_guid_sequence) {|n| "some_entry_guid_#{n}"}

  factory :deleted_entry do
    guid {generate :deleted_entry_guid_sequence}
    feed
  end
end
