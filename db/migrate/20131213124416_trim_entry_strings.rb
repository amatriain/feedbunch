class TrimEntryStrings < ActiveRecord::Migration[5.2]
  def change
    Entry.all.find_each do |entry|
      begin
        entry.title = entry.title.try(:strip) if entry.title != entry.title.try(:strip)
        entry.url = entry.url.try(:strip) if entry.url != entry.url.try(:strip)
        entry.author = entry.author.try(:strip) if entry.author != entry.author.try(:strip)
        entry.content = entry.content.try(:strip) if entry.content != entry.content.try(:strip)
        entry.summary = entry.summary.try(:strip) if entry.summary != entry.summary.try(:strip)
        entry.guid = entry.guid.try(:strip) if entry.guid != entry.guid.try(:strip)
        entry.save! if entry.changed?
      rescue
        # If a duplicate entry is found when trimming, keep one of them
        if Entry.exists? feed_id: entry.id, guid: entry.guid.try(:strip)
          entry.destroy
        end
      end
    end
  end
end
