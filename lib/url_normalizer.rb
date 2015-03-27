##
# Class with methods related to normalizing URLs.

class URLNormalizer

  ##
  # Normalize the passed URL:
  # - If the URL contains non-ascii characters, convert to ASCII using punycode
  # (see http://en.wikipedia.org/wiki/Internationalized_domain_name)
  # - Make sure that the URL passed as argument has an http:// or https://scheme.
  #
  # Receives as argument an URL string.
  #
  # The algorithm for scheme manipulations performed by the method is:
  # - If the URL has no scheme it is returned prepended with http://
  # - If the URL has a feed: or feed:// scheme, it is removed and an http:// scheme added if necessary.
  # For details about this uri-scheme see http://en.wikipedia.org/wiki/Feed_URI_scheme
  # - If the URL has an http:// or https:// scheme, it is returned untouched.
  #
  # If a nil or empty string is passed, returns nil.

  def self.normalize_url(url)
    # Check that the passed string is contains something
    return nil if url.blank?

    normalized_url = url.strip

    # If the url has the feed:// or feed: uri-schemes, remove them.
    # The order in which these removals happen is critical, don't change it!!!
    normalized_url.sub! /\Afeed:\/\//i, ''
    normalized_url.sub! /\Afeed:/i, ''

    # If the url is scheme relative, remove the leading '//', later 'http://' will be prepended
    normalized_url.sub! /\A\/\//, ''

    # If url has no http or https scheme, add http://
    unless normalized_url =~ /\Ahttp:\/\//i || normalized_url =~ /\Ahttps:\/\//i
      Rails.logger.info "Value #{url} has no http or https URI scheme, trying to add http:// scheme"
      normalized_url = "http://#{normalized_url}"
    end

    normalized_url = Addressable::URI.parse(normalized_url).normalize.to_s
    return normalized_url
  end
end