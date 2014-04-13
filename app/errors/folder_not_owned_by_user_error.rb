## Error raised when a user tries to perform an operation with a folder he doesn't own.
#
# It inherits from StandardError, implements no new methods or attributes.

class FolderNotOwnedByUserError < StandardError
end