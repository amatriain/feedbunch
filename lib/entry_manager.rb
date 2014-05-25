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
  #
  # If during processing there is a problem with an entry, it is skipped and the next one is processed,
  # instead of failing the whole process.

  def self.save_new_entries(feed, entries)
    entries.reverse_each do |entry|
      begin
        guid = entry.entry_id || entry.url
        if guid.blank?
          Rails.logger.error "Received entry without guid or url for feed #{feed.id} - #{feed.title}. Skipping it."
          next
        end

        if Entry.exists? guid: guid, feed_id: feed.id
          Rails.logger.debug "Already existing entry fetched for feed #{feed.fetch_url} - title: #{entry.title} - guid: #{entry.entry_id}. Ignoring it"
        elsif DeletedEntry.exists? guid: guid, feed_id: feed.id
          Rails.logger.debug "Already deleted entry fetched for feed #{feed.fetch_url} - title: #{entry.title} - guid: #{entry.entry_id}. Ignoring it"
        else
          Rails.logger.debug "Saving in the database new entry for feed #{feed.fetch_url} - title: #{entry.title} - guid: #{entry.entry_id}"
          entry_hash = self.entry_to_hash entry, guid
          feed.entries.create! entry_hash
        end

      rescue => e
        Rails.logger.error "There's been a problem processing a fetched entry from feed #{feed.id} - #{feed.title}. Skipping entry."
        Rails.logger.error e.message
        Rails.logger.error e.backtrace
        next
      end
    end
  end

  private

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

    entry_hash = {title: entry.title,
                  url: entry.url,
                  author: entry.author,
                  content: content,
                  summary: entry.summary,
                  published: entry.published,
                  guid: guid}
    Rails.logger.debug "Obtained attributes hash for entry: #{entry_hash}"
    return entry_hash
  end
end