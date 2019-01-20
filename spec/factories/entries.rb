# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  sequence(:entry_title_sequence) {|n| "some_entry_title_#{n}"}
  sequence(:entry_url_sequence) {|n| "http://some.entry.url.#{n}.com"}
  sequence(:entry_summary_sequence) {|n| "some_entry_summary_#{n}"}
  sequence(:entry_guid_sequence) {|n| "some_entry_guid_#{n}"}

  factory :entry do
    title {generate :entry_title_sequence}
    url {generate :entry_url_sequence}
    author {''}
    content {''}
    summary {generate :entry_summary_sequence}
    published {Time.zone.now}
    guid {generate :entry_guid_sequence}
    feed
  end
end
