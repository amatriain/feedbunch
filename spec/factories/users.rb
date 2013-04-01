# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence(:user_email_sequence) {|n| "some_email_#{n}@example.com"}

  factory :user do
    email {generate :user_email_sequence}
    remember_me true
  end
end
