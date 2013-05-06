## Error raised when a user tries to subscribe to a feed he's already subscribed to.
#
# It inherits from StandardError, implements no new methods or attributes.
#
# It's normally raised from Feed.subscribe() and captured in FeedsController.create, which returns an
# HTTP 304 response.

class AlreadySubscribedError < StandardError
end