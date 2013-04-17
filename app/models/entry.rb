##
# Feed entry model. Each instance of this class represents an entry in an RSS or Atom feed.
#
# Instances of this class are saved in the database when fetching and parsing feeds. It's not intended to be
# instanced by the user.
#
# Each entry belongs to exactly one feed.
#
# Each entry is uniquely identified by its guid. Duplicate guids are not allowed.
#
# Attributes of the model:
# - title
# - url
# - author
# - content
# - summary
# - published
# - guid
#
# Title, url and guid are mandatory. Urls are validated with this regex:
#   /\Ahttps?:\/\/.+\..+\z/

class Entry < ActiveRecord::Base
  attr_accessible #none

  belongs_to :feed
  validates :feed_id, presence: true

  validates :title, presence: true
  validates :url, presence: true, format: {with: /\Ahttps?:\/\/.+\..+\z/}
  validates :guid, presence: true, uniqueness: {case_sensitive: false}
end
