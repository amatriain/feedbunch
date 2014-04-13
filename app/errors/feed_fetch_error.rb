## Error raised when something goes wrong trying to fetch a feed.
#
# It inherits from StandardError, implements no new methods or attributes.
#
# It's normally raised from FeedClient#fetch.

class FeedFetchError < StandardError
end