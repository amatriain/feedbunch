##
# This module has functions that help in the handling of URIs.

module UriHelpers

  ##
  # Ensure that the URL passed as argument has an http:// or https://scheme.
  #
  # Receives as argument an URL string.
  #
  # If the URL has no scheme it is returned prepended with http://
  #
  # If the URL has a feed: or feed:// scheme, it is removed and an http:// scheme added if necessary.
  # For details about this uri-scheme see http://en.wikipedia.org/wiki/Feed_URI_scheme
  #
  # If the URL has an http:// or https:// scheme, it is returned untouched.

  def ensure_scheme(url)
    url_stripped = url.strip

    # If the url has the feed:// or feed: uri-schemes, remove them.
    # The order in which these removals happen is critical, don't change it!!!
    url_stripped.sub! /\Afeed:\/\//, ''
    url_stripped.sub! /\Afeed:/, ''

    uri = URI.parse url_stripped
    if !uri.kind_of?(URI::HTTP) && !uri.kind_of?(URI::HTTPS)
      Rails.logger.info "Value #{url_stripped} has no URI scheme, trying to add http:// scheme"
      fixed_url = URI::HTTP.new('http', nil, url_stripped, nil, nil, nil, nil, nil, nil).to_s
    else
      fixed_url = url_stripped
    end
    return fixed_url
  end
end