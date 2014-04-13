## Error raised when a user tries to create a new folder with the same title as another of his folders.
#
# It inherits from StandardError, implements no new methods or attributes.

class FolderAlreadyExistsError < StandardError
end