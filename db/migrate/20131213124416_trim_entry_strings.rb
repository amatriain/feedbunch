class TrimEntryStrings < ActiveRecord::Migration
  def change
    Entry.all.each do |entry|
      entry.title = entry.title.try :strip
      entry.url = entry.url.try :strip
      entry.author = entry.author.try :strip
      entry.content = entry.content.try :strip
      entry.summary = entry.summary.try :strip
      entry.guid = entry.guid.try :strip
      entry.save!
    end
  end
end
