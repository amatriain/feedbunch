##
# Main controller of the application. Options set here affect the whole application.

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, prepend: true

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_locale

  after_action :set_csrf_cookie_for_angularjs

  private

  ##
  # Set locale for the current request.
  #
  # The locale selected by the currently authenticated user, if any, takes precedence.
  # Otherwise if a "locale" parameter is passed, this will be the value used.
  # Otherwise the first available locale from the accept-language header sent by the client will be used.
  # If no locale is available from the accept-language header, english locale will the last fallback.

  def set_locale
    if current_user&.locale
      I18n.locale = current_user.locale
    elsif params[:locale].present?
      I18n.locale = params[:locale]
    else
      I18n.locale = http_accept_language.compatible_language_from I18n.available_locales || I18n.default_locale
    end
  end

  ##
  # Locale parameter is appended to all generated URLs. This way even Devise redirects
  # preserve the currently selected locale.

  def self.default_url_options(options={})
    options.merge({ :locale => I18n.locale })
  end

  ##
  # Handle an error raised during action processing.
  # It just logs the error and returns an HTTP status code, depending
  # on the kind of error raised.

  def handle_error(error)
    if error.is_a? ActiveRecord::RecordNotFound
      head 404
    elsif error.is_a? AlreadySubscribedError
      # If user is already subscribed to the feed, return 304
      head 304
    elsif error.is_a? NotSubscribedError
      # If user is not subscribed to the feed, return 404
      head 404
    elsif error.is_a? FolderAlreadyExistsError
      # If user already has a folder with the same title, return 304
      head 304
    elsif error.is_a? FolderNotOwnedByUserError
      # If user tries an operation on a folder he doesn't own, return 404
      head 404
    elsif error.is_a? OpmlImportError
      # If an error happens when importing subscription data, redirect to main application page
      redirect_to read_path
    elsif error.is_a? BlacklistedUrlError
      # If user attempts to subscribe to a blacklisted url, return 403
      head 403
    elsif error.is_a? ActionController::UnknownFormat
      # If an unsupported format is requested (e.g. requesting HTML from an API controller) return 406
      head 406
    else
      Rails.logger.error error.message
      Rails.logger.error error.backtrace
      head 500
    end
  end

  ##
  # Configure Devise controllers to accept additional parameters from a POST.

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit :sign_up, keys: [:name, :locale, :timezone]
    devise_parameter_sanitizer.permit :account_update, keys: [:name, :locale, :timezone, :kb_shortcuts_enabled,
                                                               :quick_reading, :open_all_entries]
  end

  ##
  # Set a cookie called "XSRF-TOKEN" with the CSRF token associated with the current user session.
  # This way the angularjs client can send it back in the X-CSRF-Token so that the protect_from_forgery filter
  # does not block requests.

  def set_csrf_cookie_for_angularjs
    cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
  end

  ##
  # Convert a string parameter to boolean. The value of the param must be "true" or "false", otherwise an error is raised.
  # Receives as arguments:
  # - a symbol indicating the parameter to convert
  # - the params object, sanitized by the strong parameters function if necessary (if it's going to be used for a DB update or insert)

  def param_str_to_boolean(param_sym, params)
    param_str = params[param_sym]
    param = nil

    if param_str == 'true'
      param = true
    elsif param_str == 'false'
      param = false
    elsif !param_str.nil?
      Rails.logger.warn "Unexpected value received for #{param_sym}: #{param_str}"
      raise ActionController::ParameterMissing.new 'show_main_tour'
    end

    return param
  end
end
