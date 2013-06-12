##
# This class extracts subscriptions data from a zip file exported from Google Reader, and
# imports those subscriptions to Feedbunch, so that the user that uploaded the zip file
# gets subscribed to the feeds.
#
# Folders are also imported, and feeds moved into folders as necessary.
#
# Imported feeds that were not in the database are fetched, to populate their current entries.
#
# After finishing successfully the zip file is removed from the filesystem.

class SubscriptionsImporter
  # To change this template use File | Settings | File Templates.
end