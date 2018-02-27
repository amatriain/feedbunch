# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :entry_state do
    read false
    user
    entry
    published Time.zone.now
    entry_created_at Time.zone.now

    factory :entry_read do
      read true
      user
      entry
    end
  end
end
