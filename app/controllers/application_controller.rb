##
# Main controller of the application. Options set here affect the whole application.

class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :configure_permitted_parameters, if: :devise_controller?
  before_filter :set_locale

  private

  ##
  # Set locale for the current request.
  # If a "locale" parameter is passed, this will be the value used. Otherwise the default locale :en will be used.
  #
  # If the locale passed does not exist, the default locale :en will be used if the following is set in application.rb:
  #   config.i18n.fallbacks = true

  def set_locale
    if params[:locale].present?
      I18n.locale = params[:locale]
    elsif current_user.try(:locale)
      I18n.locale = current_user.locale
    else
      I18n.locale = http_accept_language.compatible_language_from I18n.available_locales || I18n.default_locale
    end
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
    elsif error.is_a? ImportDataError
      # If an error happens when importing subscription data, redirect to main application page
      redirect_to read_path
    else
      Rails.logger.error error.message
      Rails.logger.error error.backtrace
      head status: 500
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) << :locale
  end

end
