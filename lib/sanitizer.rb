##
# Class with methods related to sanitizing user input to remove potentially malicious input.

class Sanitizer

  ##
  # Sanitize the passed string, removing any tags to leave only plain text. This avoids users entering malicious
  # markup in text fields (e.g. URL field in subscribe popup).
  #
  # Receives as argument a string.
  #
  # If a nil or empty string is passed, returns nil.

  def self.sanitize_plaintext(unsanitized_text)
    # Check that the passed string contains something
    return nil if unsanitized_text.blank?
    sanitized_text = ActionController::Base.helpers.strip_tags(unsanitized_text)&.strip
    return sanitized_text
  end
end
