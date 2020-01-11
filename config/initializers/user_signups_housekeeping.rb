# Interval after which an unconfirmed signup will be discarded
Rails.application.config.discard_unconfirmed_signups_after = 1.month

# Intervals to send reminders to unconfirmed users
Rails.application.config.first_confirmation_reminder_after = 1.day
Rails.application.config.second_confirmation_reminder_after = 1.week