require 'nokogiri'

##
# Background job to import an OPML data file with subscriptions data for a user.
# It also enqueues updates of any new feeds created (existing feeds are assumed
# to have been updated in the last hour and so don't need an update right now).
#
# Its perform method will be invoked from a Resque worker.

class ImportSubscriptionsJob
  @queue = :update_feeds

  ##
  # Import an OPML file with subscriptions for a user, and then deletes it.
  #
  # Receives as arguments:
  # - the name of the file
  # - the id of the user who is importing the file
  #
  # The file must be saved in the $RAILS_ROOT/uploads folder.
  #
  # This method is intended to be invoked from Resque, which means it is performed in the background.

  def self.perform(filename, user_id)
    user = User.find user_id
    docXml = Nokogiri::XML File.open(filename)

    # Count total number of feeds
    user.data_import.total_feeds = self.count_total_feeds docXml
    user.data_import.save

    docXml.xpath('/opml/body//outline[@type="rss"]').each do

    end

  end

  private

  ##
  # Count the number of feeds in an OPML file.
  # Receives as argument an OPML document parsed by Nokogiri.
  # Returns the number of feeds in the document.

  def self.count_total_feeds(docXml)
    return docXml.xpath 'count(/opml/body//outline[@type="rss"])'
  end
end