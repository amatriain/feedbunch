# frozen_string_literal: true

## Error raised when a user tries to perform an action which requires to be subscribed, on a feed
# to which he's not subscribed.
#
# It inherits from StandardError, implements no new methods or attributes.

class NotSubscribedError < StandardError
end