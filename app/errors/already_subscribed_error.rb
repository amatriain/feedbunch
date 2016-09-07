## Error raised when a user tries to subscribe to a feed he's already subscribed to.
#
# Besides its StandardError inheritence, it adds a 'feed' attribute that has the feed to which the user
# is already subscribed.

class AlreadySubscribedError < StandardError
  attr_reader :feed

  def initialize(feed)
    @feed = feed
  end
end