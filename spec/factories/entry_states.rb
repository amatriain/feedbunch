# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :entry_state do
    read false
    user
    entry

    factory :entry_read do
      read true
      user
      entry
    end
  end
end
