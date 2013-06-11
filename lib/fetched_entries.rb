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
    entries.each do |f|
      begin
        # If entry is already in the database, update it
        guid = f.entry_id || f.url
        if guid.blank?
          Rails.logger.error "Received entry without guid or url for feed #{feed.id} - #{feed.title}. Skipping it."
          next
        end
        if Entry.exists? guid: guid
          e = Entry.where(guid: guid).first
          Rails.logger.info "Updating already saved entry for feed #{feed.fetch_url} - title: #{f.title} - guid: #{guid}"
          # Otherwise, save a new entry in the DB
        else
          e = Entry.new
          Rails.logger.info "Saving in the database new entry for feed #{feed.fetch_url} - title: #{f.title} - guid: #{f.entry_id}"
        end

        e.title = f.title
        e.url = f.url
        e.author = f.author
        e.content = f.content
        e.summary = f.summary
        e.published = f.published
        e.guid = guid
        feed.entries << e
        e.save
      rescue => e
        Rails.logger.error "There's been a problem processing a fetched entry from feed #{feed.id} - #{feed.title}. Skipping entry."
        Rails.logger.error e.message
        Rails.logger.error e.backtrace
        next
      end
    end
  end
end