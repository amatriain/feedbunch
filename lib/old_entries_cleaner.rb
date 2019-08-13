##
# Class with methods related to deleting old entries from the database.

class OldEntriesCleaner

  ##
  # Delete entries above the configured max_feed_entries limit. This config option sets
  # the maximum number of entries that the app will keep for each feed.
  #
  # Receives as argument the feed for which old entries will be deleted.
  #
  # Old entries (based on their published attribute) will be deleted first, so that
  # newer entries up to max_feed_entries will be kept.do
  #
  # Deleting an entry implies destroying the Entry instance (which removes the record from the
  # entries table, as well as associated EntryState instances etc) and creating a new DeletedEntry
  # instance with the same guid and feed_id (to ensure that deleted entries won't be saved in the
  # database again, even if they are present in a feed xml retrieved in the future).

  def self.cleanup(feed)
    max_entries = Feedbunch::Application.config.max_feed_entries
    entries_count = feed.entries.count
    if entries_count > max_entries
      entries_deleted_count = entries_count - max_entries
      Rails.logger.info "Feed #{feed.id} - #{feed.title} has more than the maximum #{max_entries}. Deleting #{entries_deleted_count} older entries"
      old_entries = feed.entries.order(published: :asc, created_at: :asc, id: :asc).limit entries_deleted_count
      old_entries.each do |entry|
        entry.destroy
        feed.deleted_entries.create guid: entry.guid, unique_hash: entry.unique_hash
      end
    end
  end
end