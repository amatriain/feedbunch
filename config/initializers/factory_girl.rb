# Rails generators generate FactoryGirl factories instead of fixtures
Rails.application.config.generators do |g|
  g.fixture_replacement :factory_girl
end