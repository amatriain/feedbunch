##
# Main controller of the application. Options set here affect the whole application.

class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :configure_permitted_parameters, if: :devise_controller?
  before_filter :set_locale

  after_filter :set_csrf_cookie_for_angularjs

  private

  ##
  # Set locale for the current request.
  #
  # The locale selected by the currently authenticated user, if any, takes precedence.
  # Otherwise if a "locale" parameter is passed, this will be the value used.
  # Otherwise the first available locale from the accept-language header sent by the client will be used.
  # If no locale is available from the accept-language header, english locale will the last fallback.

  def set_locale
    if current_user.try(:locale)
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
  # After a successful login, a user is redirected to the feeds list

  def after_sign_in_path_for(resource)
    read_path
  end

  ##
  # Handle an error raised during action processing.
  # It just logs the error and returns an HTTP status code, depending
  # on the kind of error raised.

  def handle_error(error)
    if error.is_a? ActiveRecord::RecordNotFound
      head status: 404
    elsif error.is_a? AlreadySubscribedError
      # If user is already subscribed to the feed, return 304
      head status: 304
    elsif error.is_a? NotSubscribedError
      # If user is not subscribed to the feed, return 404
      head status: 404
    elsif error.is_a? FolderAlreadyExistsError
      # If user already has a folder with the same title, return 304
      head status: 304
    elsif error.is_a? FolderNotOwnedByUserError
      # If user tries an operation on a folder he doesn't own, return 404
      head status: 404
    elsif error.is_a? OpmlImportError
      # If an error happens when importing subscription data, redirect to main application page
      redirect_to read_path
    else
      Rails.logger.error error.message
      Rails.logger.error error.backtrace
      head status: 500
    end
  end

  ##
  # Configure Devise controllers to accept additional parameters from a POST.

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) << :name << :locale << :timezone
    devise_parameter_sanitizer.for(:account_update) << :name << :locale << :timezone << :quick_reading << :open_all_entries
  end

  ##
  # Set a cookie called "XSRF-TOKEN" with the CSRF token associated with the current user session.
  # This way the angularjs client can send it back in the X-CSRF-Token so that the protect_from_forgery filter
  # does not block requests.

  def set_csrf_cookie_for_angularjs
    cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
  end

  # TODO after beta stage remove this method override to allow anyone to invite friends

  ##
  #

  def authenticate_inviter!
    head status: 403 if !current_user.admin
  end
end
