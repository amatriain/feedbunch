##
# Class with methods related to normalizing URLs.

class URLNormalizer

  ##
  # Normalize the passed URL:
  # - Make sure that the URL passed as argument has an http:// or https://scheme.
  # - If the URL contains non-ascii characters, convert to ASCII using punycode
  # (see http://en.wikipedia.org/wiki/Internationalized_domain_name)
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

  def self.normalize_feed_url(url)
    # Check that the passed string contains something
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

  ##
  # Normalize an entry URL:
  # - make sure that it is an absolute URL, prepending the feed host if necessary
  # - make sure that the URL has an http or https scheme, using the feed's scheme by default
  # - If the URL contains non-ascii characters, convert to ASCII using punycode
  # (see http://en.wikipedia.org/wiki/Internationalized_domain_name)
  #
  # Receives as argument an URL string.
  #
  # If a nil or empty string is passed, returns nil.

  def self.normalize_entry_url(url, entry)
    # Check that the passed string contains something
    return nil if url.blank?

    normalized_url = url.strip

    # Addressable treats scheme-relative URIs as relative URIs, but we do not want to add the feed host etc to
    # scheme-relative URIs in entries. So, if URI is scheme-relative, skip the manipulations performed on relative
    # URIs.
    if normalized_url =~ /\A\/\//
      Rails.logger.info "Value #{url} is a scheme relative URI, leaving it unchanged"
    # Data-uris do not need to be further manipulated
    elsif normalized_url =~ /\Adata:/
      Rails.logger.info "Value #{url} is a data-uri, leaving it unchanged"
    # Object-URLs (pointing to in-memory blobs) are not allowed because of security concerns, they are removed
    elsif normalized_url =~ /\Ablob:/
      Rails.logger.info "Value #{url} is an object-url (blob), removing it"
      normalized_url = ''
    else
      # if the entry url is relative, try to make it absolute using the feed's host
      parsed_uri = Addressable::URI.parse normalized_url
      if parsed_uri.relative?
        # Path must begin with a '/'
        normalized_url = "/#{normalized_url}" if parsed_uri.path[0] != '/'

        # Use host from feed URL, or if the feed only has a fetch URL use it instead.
        uri_feed = entry_feed_uri entry
        normalized_url = "#{uri_feed.host}#{normalized_url}"
      end

      # If url has no http or https scheme, add http://
      unless normalized_url =~ /\Ahttp:\/\//i || normalized_url =~ /\Ahttps:\/\//i
        # Do not recalculate feed URI if previously calculated.
        uri_feed ||= entry_feed_uri entry
        Rails.logger.info "Value #{url} has no http or https URI scheme, trying to add scheme from feed url #{uri_feed}"
        normalized_url = "#{uri_feed.scheme}://#{normalized_url}"
      end
    end

    normalized_url = Addressable::URI.parse(normalized_url).normalize.to_s
    return normalized_url
  end

  #############################
  # PRIVATE CLASS METHODS
  #############################

  ##
  # Returns an Addressable::URI object with the URI of the feed to which an entry belongs.
  # It uses the url attribute of the feed or, if url is blank, it uses the feeds's fetch_url attribute.
  # Receives an entry as argument.

  def self.entry_feed_uri(entry)
    if entry.feed.url.present?
      uri_feed = Addressable::URI.parse entry.feed.url
    else
      uri_feed = Addressable::URI.parse entry.feed.fetch_url
    end
    return uri_feed
  end
  private_class_method :entry_feed_uri
end
