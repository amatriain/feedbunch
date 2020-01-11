# Do not raise an error if an unavailable locale is passed (the default :en will be used,
# see config.i18n.fallbacks below)
Rails.application.config.i18n.enforce_available_locales = false

# The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
# config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
# config.i18n.default_locale = :de

# Fall back to the default locale ("en" if config.i18n.default_locale is not configured)
# if the locale sent by the user does not exist
Rails.application.config.i18n.fallbacks = [I18n.default_locale]

# List of currently available locales
I18n.available_locales = [:en, :es]