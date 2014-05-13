# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence(:export_filename_sequence) {|n| "some_filename_#{n}.opml"}

  factory :opml_export_job_state do
    state 'NONE'
    show_alert true
    user
    filename {(state=='SUCCESS')?generate(:export_filename_sequence):nil}
    export_date {Time.zone.now}
  end
end
