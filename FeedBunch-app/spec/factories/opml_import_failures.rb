# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  sequence(:opml_import_failure_url_sequence) {|n| "http://some.failed.feed_#{n}.com"}

  factory :opml_import_failure do
    url {generate :opml_import_failure_url_sequence}
    opml_import_job_state
  end
end
