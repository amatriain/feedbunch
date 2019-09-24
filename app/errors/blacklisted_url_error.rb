# frozen_string_literal: true

## Error raised when a user tries to subscribe to a feed with a blacklisted url or fetch_url.
#
# It inherits from StandardError, implements no new methods or attributes.

class BlacklistedUrlError < StandardError
end