# frozen_string_literal: true

## Error raised when something goes wrong trying to import a subscriptions data file.
#
# It inherits from StandardError, implements no new methods or attributes.

class OpmlImportError < StandardError
end