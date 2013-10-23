##
# Class to clean up old entries

class OldEntryCleaner

  ##
  # Clean up old entries from a feed.
  #
  # Receives as argument the feed to clean up.
  #
  # Entries with a publish date older than one year are deleted. A minimum of
  # 10 entries are kept for the feed.

  def self.cleanup(feed)
    if feed.entries.count > 10
      old_threshold = DateTime.now - 1.year
      old_entries = Entry.where('published < ?', old_threshold).order('published ASC')
      old_entries.each do |entry|
        entry.destroy
        return if feed.entries.count <= 10
      end
    end
  end
end