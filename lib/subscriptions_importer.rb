##
# This class manages import of subscription data from Google Reader into Feedbunch

class SubscriptionsImporter

  ##
  # This method extracts subscriptions data from an XML file (probably exported from Google Reader), and
  # imports those subscriptions to Feedbunch, so that the user that uploaded the file
  # gets subscribed to the feeds.
  #
  # Optionally the file can be zipped; this is the format one gets when exporting from Google.
  #
  # Folders are also imported, and feeds moved into folders as necessary.
  #
  # Imported feeds that were not in the database are fetched, to populate their current entries.

  def self.import_subscriptions(file, user)

  end
end