# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence(:user_email_sequence) {|n| "some_email_#{n}@example.com"}
  sequence(:user_name_sequence) {|n| "some_name_#{n}"}
  sequence(:user_password_sequence) {|n| "some_password_#{n}"}

  factory :user do
    email {generate :user_email_sequence}
    name {generate :user_name_sequence}
    password {generate :user_password_sequence}
    remember_me true
    confirmed_at Time.zone.now
    admin false
    locale 'en'
    timezone 'UTC'
    quick_reading false
    open_all_entries false
    show_main_tour false
    show_mobile_tour false
    show_feed_tour false
    show_entry_tour false
    subscriptions_updated_at Time.zone.now
    folders_updated_at Time.zone.now
    refresh_feed_jobs_updated_at Time.zone.now
    subscribe_jobs_updated_at Time.zone.now

    factory :user_unconfirmed do
      confirmed_at nil
    end

    factory :user_admin do
      admin true
    end
  end
end
