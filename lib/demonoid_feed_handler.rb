##
# Special handling of the feeds from www.demonoid.pw

class DemonoidFeedHandler

  ##
  # Special handling of Demonoid entries before validation (this is, before saving them).
  #
  # Demonoid changes the guid of entries over time, which would result in duplicated entries (the same entry with
  # different guids, which Feedbunch sees as different entries); this class fixes that behavior.
  #
  # The guid for a particular entry changes over time like this:
  #   http://www.demonoid.pw/files/details/3400534/0687950652/
  #   http://www.demonoid.pw/files/details/3400534/002130706434/
  #   http://www.demonoid.pw/files/details/3400534/00616663814/
  #   http://www.demonoid.pw/files/details/3400534/00570968806/
  #
  # We can discard the last part of the guid, replacing the guid with http://www.demonoid.pw/files/details/3400534/
  # in all those cases; this results in an entry guid that does not change over time.
  #
  # This fix is of course brittle and could break at any time if Demonoid changes the algorithm they use to generate
  # guids.
  #
  # Receives as argument the entry to handle.

  def self.handle_entry(entry)
    regex = /\A(http:\/\/www\.demonoid\.pw\/files\/details\/[^\/]+\/)[^\/]+\/\z/
    if regex =~ entry.guid
      match = regex.match entry.guid
      new_guid = match[1]
      Rails.logger.info "Entry #{entry.title} belongs to Demonoid. Replacing guid #{entry.guid} with #{new_guid} to have a guid that does not change over time"
      entry.guid = new_guid
    end
    return nil
  end
end