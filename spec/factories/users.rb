# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence(:user_email_sequence) {|n| "some_email_#{n}@example.com"}
  sequence(:user_password_sequence) {|n| "some_password_#{n}"}

  factory :user do
    email {generate :user_email_sequence}
    password {generate :user_password_sequence}
    remember_me true
    confirmed_at Time.now
    admin false
    locale 'en'
    timezone 'UTC'
    quick_reading false

    factory :user_unconfirmed do
      confirmed_at nil
    end

    factory :user_admin do
      admin true
    end
  end
end
