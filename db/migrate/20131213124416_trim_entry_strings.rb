class TrimEntryStrings < ActiveRecord::Migration
  def change
    Entry.all.find_each do |entry|
      begin
        entry.title = entry.title.try :strip
        entry.url = entry.url.try :strip
        entry.author = entry.author.try :strip
        entry.content = entry.content.try :strip
        entry.summary = entry.summary.try :strip
        entry.guid = entry.guid.try :strip
        entry.save!
      rescue
        # If a duplicate entry is found when trimming, keep one of them
        if Entry.exists? feed_id: entry.id, guid: entry.guid.try(:strip)
          entry.destroy
        end
      end
    end
  end
end
