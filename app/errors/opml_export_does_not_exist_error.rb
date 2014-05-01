## Error raised when the user tries to retrieve his OPML export file, but it doesn't exist.
#
# It inherits from StandardError, implements no new methods or attributes.

class OpmlExportDoesNotExistError < StandardError
end