##
# Class to save or update in the database a collection of fetched feed entries.

class FetchedEntries
  ##
  # Save or update feed entries in the database.
  #
  # For each entry, if an entry with the same guid already exists in the database, update it with
  # the values passed as argument to this method. Otherwise save it as a new entry in the database.
  #
  # The argument passed are:
  # - the feed to which the entries belong (an instance of the Feed model)
  # - an Enumerable with the feed entries to save.
  #
  # If during processing there is a problem with an entry, it is skipped and the next one is processed,
  # instead of failing the whole process.

  def self.save_or_update_entries(feed, entries)
    entries.each do |entry|
      begin
        guid = entry.entry_id || entry.url
        if guid.blank?
          Rails.logger.error "Received entry without guid or url for feed #{feed.id} - #{feed.title}. Skipping it."
          next
        end

        entry_hash = self.entry_to_hash entry, guid

        if Entry.exists? guid: guid
          # If entry is already in the database, update it
          Rails.logger.info "Updating already saved entry for feed #{feed.fetch_url} - title: #{entry.title} - guid: #{guid}"
          e = Entry.where(guid: guid).first
          e.update entry_hash
        else
          # Otherwise, save a new entry in the DB
          Rails.logger.info "Saving in the database new entry for feed #{feed.fetch_url} - title: #{entry.title} - guid: #{entry.entry_id}"
          e = Entry.new
          feed.entries.create entry_hash
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
    entry_hash = entry.to_h.slice! :title, :url, :author, :content, :summary, :published
    entry_hash[:guid] = guid
  end
end