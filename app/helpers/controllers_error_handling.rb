##
# Module with functions related to error handling in controllers

module ControllersErrorHandling

  private

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
    elsif error.is_a? FolderAlreadyExistsError
      # If user already has a folder with the same title, return 304
      head status: 304
    else
      Rails.logger.error error.message
      Rails.logger.error error.backtrace
      head status: 500
    end
  end
end