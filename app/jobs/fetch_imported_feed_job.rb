##
# Background job to fetch for the first time a feed just created as part of an OPML file import.

class FetchImportedFeedJob
  @queue = :update_feeds

  ##
  # Fetch a new feed, just created as part of an OPML file import.
  # When fetch has finished, update the processed feeds count of the data_import for the user that requested the import, so that
  # he can see the import progress
  #
  # Receives as arguments:
  # - the id of the feed to fetch
  # - the id of the user that requested the import
  #
  # This method is intended to be invoked from Resque, which means it is performed in the background.

  def self.perform

  end
end