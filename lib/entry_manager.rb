require 'encoding_manager'
require 'sanitizer'

##
# Class to save or update in the database a collection of entries fetched from a feed.

class EntryManager

  ##
  # Save new feed entries in the database.
  #
  # For each entry passed, if an entry with the same guid for the same feed already exists in the database,
  # ignore it. Also, if an entry with the same guid for the same feed has been deleted in the past, indicated
  # by a record in the deleted_entries table, ignore it. Otherwise save it as a new entry in the database.
  #
  # The argument passed are:
  # - the feed to which the entries belong (an instance of the Feed model)
  # - an Enumerable with the feed entries to save.
  # - encoding of the feed. Necessary because Feedjira sometimes receives a non-utf8 feed as input and returns a parsed
  # feed object with e.g. entry titles incorrectly marked as utf-8, when actually the internal representation is in the same encoding
  # as the input. This makes necessary converting Feedjira outputs to the input encoding.
  #
  # If during processing there is a problem with an entry, it is skipped and the next one is processed,
  # instead of failing the whole process.

  def self.save_new_entries(feed, entries, encoding)
    entries.reverse_each do |entry|

      begin
        set_entry_encoding entry, encoding
        guid = entry.entry_id || entry.url
        if guid.blank?
          Rails.logger.warn "Received entry without guid or url for feed #{feed.id} - #{feed.title}. Skipping it."
          next
        end

        # Sanitize and trim guid; necessary to check if the entry already exists, because the Entry model
        # changes the guid this way before saving.
        guid = Sanitizer.sanitize_plaintext guid

        if Entry.exists? guid: guid, feed_id: feed.id
          Rails.logger.debug "Already existing entry fetched for feed #{feed.fetch_url} - title: #{entry.title} - guid: #{entry.entry_id}. Ignoring it"
        elsif DeletedEntry.exists? guid: guid, feed_id: feed.id
          Rails.logger.debug "Already deleted entry fetched for feed #{feed.fetch_url} - title: #{entry.title} - guid: #{entry.entry_id}. Ignoring it"
        else
          Rails.logger.debug "Saving in the database new entry for feed #{feed.fetch_url} - title: #{entry.title} - guid: #{entry.entry_id}"
          entry_hash = entry_to_hash entry, guid
          feed.entries.create! entry_hash
        end

      rescue => e
        Rails.logger.error "There's been a problem processing a fetched entry from feed #{feed.id} - #{feed.title}. Skipping entry."
        Rails.logger.error e.message
        # Do not print backtrace for AR validation errors, it's just white noise
        Rails.logger.error e.backtrace unless e.is_a? ActiveRecord::RecordInvalid
        next
      end
    end
  end

  #############################
  # PRIVATE CLASS METHODS
  #############################

  ##
  # Make sure that all entry attributes from a Feejira entry are valid for their current encoding; otherwise the encoding
  # is forced to the one passed as argument.
  #
  # This is intended for the case in which Feedjira sets an incorrect encoding. This may happen if e.g. the correct encoding
  # is reported in the HTTP headers for the feed, but the feed XML reports an incorrect encoding in the opening tag.

  def self.set_entry_encoding(entry, encoding)
    entry.title = EncodingManager.set_encoding entry.title, encoding
    entry.url = EncodingManager.set_encoding entry.url, encoding
    entry.author = EncodingManager.set_encoding entry.author, encoding
    entry.content = EncodingManager.set_encoding entry.content, encoding
    entry.summary = EncodingManager.set_encoding entry.summary, encoding
    entry.entry_id = EncodingManager.set_encoding entry.entry_id, encoding
  end
  private_class_method :set_entry_encoding

  ##
  # Convert an entry created by Feedjira to a hash, with just the keys needed to create an Entry instance.
  #
  # The whitelisted keys are: title, url, author, content, summary, published.
  # Also the "guid" key is inserted. This may not come directly from the object created by Feedjira, see above.
  #
  # Receives as arguments:
  # - the entry created by Feedjira
  # - the guid for the entry
  #
  # Returns a hash with the key/values necessary to create an instance of the Entry model.

  def self.entry_to_hash(entry, guid)
    # Some feed parser types do not give a "content" attribute to their entries. In
    # this case we default to the entry summary.
    if entry.respond_to? :content
      content = entry.content
    else
      content = entry.summary
    end

    # Some feeds (e.g. itunes podcasts) do not have a url tag in entries, but an enclosure tag with an url attribute
    # instead. We use the enclosure url in these cases.
    if entry.url.blank? && entry.respond_to?(:enclosure_url)
      url = entry.enclosure_url
    # Some itunes feeds are mistaken by Feedjira as Feedburner feeds. In this case the enclosure tag ends up in the
    # entry.image attribute
    elsif entry.url.blank? && entry.respond_to?(:image)
      url = entry.image
    else
      url = entry.url
    end

    entry_hash = {title: entry.title,
                  url: url,
                  author: entry.author,
                  content: content,
                  summary: entry.summary,
                  published: entry.published,
                  guid: guid}
    Rails.logger.debug "Obtained attributes hash for entry: #{entry_hash}"
    return entry_hash
  end
  private_class_method :entry_to_hash
end
