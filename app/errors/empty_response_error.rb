## Error raised when no response is returned when trying to fetch a feed.
#
# It inherits from StandardError, implements no new methods or attributes.
#
# It's normally raised from FeedClient#fetch.

class EmptyResponseError < StandardError
end