require 'loofah'

##
# Class with methods related to sanitizing user input to remove potentially malicious input.

class Sanitizer

  ##
  # Sanitize the passed string, removing any tags to leave only plain text. This avoids users entering malicious
  # markup in text fields (e.g. URL field in subscribe popup).
  #
  # Receives as argument a string.
  #
  # If a nil or empty string is passed, returns an empty string.

  def self.sanitize_plaintext(unsanitized_text)
    # Check that the passed string contains something
    return '' if unsanitized_text.blank?
    sanitized_text = Loofah.scrub_fragment(unsanitized_text, :prune).text(encode_special_chars: false)&.strip

    # Passing encode_special_chars: false to text(), which is necessary so that e.g. & characters in URL are not
    # HTML-escaped during sanitization, unfortunately means that any encoded HTML entities in the unsanitized text
    # become unencoded; e.g. if the user enters:
    #
    # &lt;script&gt;alert("pwnd")&lt;/script&gt;http://feedbunch.com
    #
    # then Loofah at this point returns:
    #
    # <script>alert("pwnd")</script>http://feedbunch.com
    #
    # which obviously is not safe. Also a malicious user could HTML-encode the & characters so that the malicious script
    # would be dangerous after a second Loofah pass, and so on.
    #
    # To make sure that the string is safe no matter how many levels of HTML-encoding an attacker introduces, I'm
    # using the fact that a safe string is the same before and after passing through Loofah. If after three passes the
    # string keeps changing every time it is scrubbed with Loofah, stop playing cat and mouse and just return an
    # empty string.
    re_sanitized_text = Loofah.scrub_fragment(sanitized_text, :prune).text(encode_special_chars: false)&.strip
    passes = 0
    while sanitized_text!=re_sanitized_text do
      passes += 1
      return '' if passes >= 3
      sanitized_text = re_sanitized_text
      re_sanitized_text = Loofah.scrub_fragment(sanitized_text, :prune).text(encode_special_chars: false)&.strip
    end

    return re_sanitized_text
  end

  ##
  # Sanitize the passed string by removing dangerous markup (scripts etc) and leaving only markup that can be
  # displayed safely to the user (images etc).
  #
  # If a nil or empty string is passed, returns an empty string.

  def self.sanitize_html(unsanitized_html)
    return '' if unsanitized_html.blank?
    config_relaxed = Feedbunch::Application.config.relaxed_sanitizer
    sanitized_html = Sanitize.fragment(unsanitized_html, config_relaxed)&.strip
    return sanitized_html
  end
end
