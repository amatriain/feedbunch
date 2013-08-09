# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence(:folder_title_sequence) {|n| "some_folder_title_#{n}"}

  factory :folder do
    title {generate :folder_title_sequence}
    user
    unread_entries 0
  end
end
