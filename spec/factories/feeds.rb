# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence(:feed_title_sequence) {|n| "some_title_#{n}"}
  sequence(:feed_url_sequence) {|n| "http://some.url.#{n}.com"}

  factory :feed do
    title {generate :feed_title_sequence}
    url {generate :feed_url_sequence}
  end
end
