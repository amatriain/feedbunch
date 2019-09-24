# frozen_string_literal: true

## Error raised when feed autodiscovery fails on a downloaded HTML document.
#
# It inherits from StandardError, implements no new methods or attributes.
#
# It's normally raised from FeedClient#fetch.

class FeedAutodiscoveryError < StandardError
end