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
  #
  # If a nil or empty string is passed, returns nil.

  def ensure_scheme(url)
    # Check that the passed string is contains something
    return nil if url.blank?

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

  ##
  # Return a params array that can be used in url_for, path_for methods. The returned params will have the
  # invitation_token if and only if this param is present in the params array sent with the current request.
  #
  # The params array for the current request must be passed.
  # Optionally a locale can also be passed; if so, the locale param will also be in the params array returned.
  #
  # This helper is used in places in which a link href may have the invitation_token and locale parameters,
  # or they may be absent from the URL instead of present but with a blank value. E.g.: locale switch links in
  # devise views must have the invitation_token param to be valid, but only in the accept invitation view; in
  # the rest of views the locale links must not have this param.

  def self.params_keep_invitation_token(params, locale: nil)
    invitation_token = params[:invitation_token]
    params = {}.
      merge( (locale.present?) ? {locale: locale} : {} ).
      merge( (invitation_token.present?) ? {invitation_token: invitation_token} : {} )
    return params
  end
end
