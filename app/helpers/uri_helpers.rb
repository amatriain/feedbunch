##
# This module has functions that help in the handling of URIs.

module UriHelpers

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
