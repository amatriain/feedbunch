require 'entry_manager'

##
# Class to parse a fetched feed.

class FeedParser

  ##
  # Try to parse an HTTP response as a feed (RSS, Atom or other formats supported by Feedjira).
  #
  # If successful:
  # - saves in the database the title and URL for the feed.
  # - saves the fetched feed entries in the database.
  #
  # Any errors raised are bubbled to be handled higher up the call chain. In particular, if the response being parsed
  # is not a feed, it's likely that it's an HTML webpage, possibly with feed autodiscovery enabled. In this case
  # this function will raise an error and it's the responsibility of the calling function to capture this error and
  # handle feed autodiscovery on the HTML.
  #
  # Receives as arguments:
  # - feed object corresponding to the feed being fetched
  # - response to be parsed
  # - encoding of the feed. Necessary because Feedjira sometimes receives a non-utf8 feed as input and returns a parsed
  # feed object with e.g. title incorrectly marked as utf-8, when actually the internal representation is in the same encoding
  # as the input. This makes necessary converting Feedjira outputs to the input encoding.
  #
  # Returns the updated feed object.

  def self.parse(feed, feed_response, encoding)
    # Preserve xhtml markup in entries
    Feedjira::Parser::Atom.preprocess_xml = true
    Feedjira::Parser::AtomFeedBurner.preprocess_xml = true
    # Use Ox for SAX parsing
    SAXMachine.handler = :ox
    feed_parsed = Feedjira::Feed.parse feed_response
    Rails.logger.info "Correctly parsed feed from url #{feed.fetch_url}"

    # Save the feed title and url.
    # Warning: don't confuse url (the url of the website generating the feed) with fetch_url (the url from which the
    # XML of the feed is fetched).
    feed_parsed.title = EncodingManager.set_encoding feed_parsed.title, encoding
    feed_parsed.url = EncodingManager.set_encoding feed_parsed.url, encoding
    Rails.logger.info "Fetched from: #{feed.fetch_url} - title: #{feed_parsed.title} - url: #{feed_parsed.url}"

    # Update feed title and feed url only of they are present in the fetched XML
    feed_title = (feed_parsed.title.present?)? feed_parsed.title : feed.title
    feed_url = (feed_parsed.url.present?)? feed_parsed.url : feed.url
    feed_attribs = {title: feed_title, url: feed_url}

    Rails.logger.debug "Current feed attributes: #{feed.attributes}"
    Rails.logger.debug "Updating feed with attributes #{feed_attribs}"
    feed.update feed_attribs

    # Save entries in the database
    EntryManager.save_new_entries feed, feed_parsed.entries, encoding

    return feed
  end
end


