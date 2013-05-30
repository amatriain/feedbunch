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

  def self.save_or_update_entries(feed, entries)
    entries.each do |f|
      # If entry is already in the database, update it
      if Entry.exists? guid: f.entry_id
        e = Entry.where(guid: f.entry_id).first
        Rails.logger.info "Updating already saved entry for feed #{feed.fetch_url} - title: #{f.title} - guid: #{f.entry_id}"
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
      e.guid = f.entry_id
      feed.entries << e
      e.save
    end
  end
end