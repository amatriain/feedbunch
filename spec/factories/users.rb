# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence(:user_email_sequence) {|n| "some_email_#{n}@example.com"}
  sequence(:user_password_sequence) {|n| "some_password_#{n}"}

  factory :user do
    email {generate :user_email_sequence}
    password {generate :user_password_sequence}
    remember_me true
  end
end
