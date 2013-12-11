##
# Class to save or update in the database a collection of entries fetched from a feed.

class EntryManager

  ##
  # Save new feed entries in the database.
  #
  # For each entry passed, if an entry with the same guid for the same feed already exists in the database,
  # ignore it. Otherwise save it as a new entry in the database.
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

        if !Entry.exists? guid: guid, feed_id: feed.id
          # Otherwise, save a new entry in the DB
          Rails.logger.debug "Saving in the database new entry for feed #{feed.fetch_url} - title: #{entry.title} - guid: #{entry.entry_id}"
          entry_hash = self.entry_to_hash entry, guid
          feed.entries.create! entry_hash
        else
          Rails.logger.debug "Already existing entry fetched for feed #{feed.fetch_url} - title: #{entry.title} - guid: #{entry.entry_id}. Ignoring it"
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
  # Convert an entry created by Feedzirra to a hash, with just the keys needed to create an Entry instance.
  #
  # The whitelisted keys are: title, url, author, content, summary, published.
  # Also the "guid" key is inserted. This may not come directly from the object created by Feedzirra, see above.
  #
  # Receives as arguments:
  # - the entry created by Feedzirra
  # - the guid for the entry
  #
  # Returns a hash with the key/values necessary to create an instance of the Entry model.

  def self.entry_to_hash(entry, guid)
    entry_hash = {title: entry.title, url: entry.url, author: entry.author, content: entry.content,
                  summary: entry.summary, published: entry.published, guid: guid}
    Rails.logger.debug "Obtained attributes hash for entry: #{entry_hash}"
    return entry_hash
  end
end