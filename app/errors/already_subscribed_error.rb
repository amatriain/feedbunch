## Error raised when a user tries to subscribe to a feed he's already subscribed to.
#
# It inherits from StandardError, implements no new methods or attributes.

class AlreadySubscribedError < StandardError
end