class RenameEntryContentHashToUniqueHash < ActiveRecord::Migration[5.2]
  def up
    rename_column :entries, :content_hash, :unique_hash
    change_column_default :entries, :unique_hash, ''

    # Calculate unique_hash for older entries
    Entry.all.order(published: :asc).each do |e|
      unique = ''
      unique += e.content if e.content.present?
      unique += e.summary if e.summary.present?
      unique += e.title
      hash = Digest::MD5.hexdigest(unique)

      # Dangerous!
      # If this entry has the same hash as an older entry (note that entries are processed in ascending order
      # by ther publish date) from the same feed, this entry is a duplicate. Delete it.
      if Entry.where('feed_id = ? AND unique_hash = ? AND id != ?', e.feed_id, hash, e.id).exists?
        e.destroy
      else
        # The entry is not a duplicate, save its unique hash in the DB
        e.update unique_hash: hash
      end
    end

    change_column_null :entries, :unique_hash, false
  end

  def down
    change_column_null :entries, :unique_hash, true
    Entry.update_all unique_hash: nil
    change_column_default :entries, :unique_hash, nil
    rename_column :entries, :unique_hash, :content_hash
  end
end
