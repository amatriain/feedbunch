# Enable or disable self-signups with the SIGNUPS_ENABLED env variable.
# If "true", new users can self-register, if "false" new users can only be
# created by an administrator. 
# Takes the value "true" by default.
signups_enabled_str = ENV.fetch("SIGNUPS_ENABLED") { "true" }
signups_enabled_str = signups_enabled_str.downcase.strip
signups_enabled = ActiveRecord::Type::Boolean.new.cast signups_enabled_str
Rails.application.config.signups_enabled = signups_enabled

if signups_enabled
    # Interval after which an unconfirmed signup will be discarded
    Rails.application.config.discard_unconfirmed_signups_after = 1.month

    # Intervals to send reminders to unconfirmed users
    Rails.application.config.first_confirmation_reminder_after = 1.day
    Rails.application.config.second_confirmation_reminder_after = 1.week
end