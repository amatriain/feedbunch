##
# This module has functions that help in the handling of URIs.

module UriHelpers

  ##
  # Ensure that the URL passed as argument has an http:// or https://schema.
  #
  # Receives as argument an URL.
  #
  # If the URL has no schema it is returned prepended with http://
  #
  # If the URL has an http:// or https:// schema, it is returned untouched.

  def ensure_schema(url)
    uri = URI.parse url
    if !uri.kind_of?(URI::HTTP) && !uri.kind_of?(URI::HTTPS)
      Rails.logger.info "Value #{url} has no URI scheme, trying to add http:// scheme"
      fixed_url = URI::HTTP.new('http', nil, url, nil, nil, nil, nil, nil, nil).to_s
    else
      fixed_url = url
    end
    return fixed_url
  end
end