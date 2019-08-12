##
# Deleted Entry model. Each instance of this class represents a feed entry that has been deleted from the
# database during an automated cleanup.
#
# Each deleted_entry belongs to exactly one feed.
#
# When an entry is deleted during an automated cleanup, a new record is inserted in the deleted_entries table.
# The "feed_id" and "guid" attributes of the new deleted_entry record are the same as those of the deleted
# entry. This means that deleted entries still occupy some space in the database, but much less because the
# entry content is not kept.
#
# Each deleted_entry is uniquely identified by its guid within the scope of a given feed.
# Duplicate guids are not allowed for a given feed.
#
# A deleted_entry with the same guid and feed_id as an already existing entry is not valid and won't be
# saved in the database (it would indicate an entry which is at once deleted and not deleted).
#
# Attributes of the model:
# - feed_id: ID of the feed to which the deleted entry belonged.
# - guid: guid of the deleted entry.
# - unique_hash: MD5 hash of the content+summary+title of the deleted entry
#
# The unique_hash attribute is not mandatory (can be nil) for backwards compatibility reasons: we cannot know calculate
# the unique hash for already deleted entries, so the attribute is left nil for older deleted entries.

class DeletedEntry < ApplicationRecord
  belongs_to :feed
  validates :feed_id, presence: true
  validates :guid, presence: true, uniqueness: {case_sensitive: true, scope: :feed_id}
  validates :unique_hash, uniqueness: {case_sensitive: true, scope: :feed_id}
  validate :entry_deleted

  private

  ##
  # Validate that the entry has been deleted (there isn't an entry record with the
  # same feed_id and either guid or unique_hash)

  def entry_deleted
    if Entry.where('feed_id = ? AND (guid = ? OR unique_hash = ?)', self.feed_id, self.guid, self.unique_hash).exists?
      Rails.logger.warn "Failed attempt to mark as deleted existing entry - guid: #{self.try :guid}, unique_hash: #{self.try :unique_hash}, published: #{self.try :published}, feed_id: #{self.feed_id}, feed title: #{self.feed.title}"
      errors.add :guid, 'entry not deleted'
    end
  end
end
