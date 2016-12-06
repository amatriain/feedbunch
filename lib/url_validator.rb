##
# Class with methods related to validating URLs.

class UrlValidator

  ##
  # Validate if a URL is a valid URL for an entry (either for the entry link, or for any link in the content, e.g.
  # images).
  #
  # A URL is a valid entry URL if it is an http or https URL, or a protocol-relative URL.
  #
  # Receives an URL string as argument. Returns a boolean: true if the URL is valid for an entry, false otherwise.

  def self.valid_entry_url?(url)
    if url =~ URI::regexp(%w{http https})
      return true
    elsif url =~ /\A\/\//
      return true
    else
      return false
    end
  end
end