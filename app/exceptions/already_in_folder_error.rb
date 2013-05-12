## Error raised when a user tries to associate a feed with a folder, when the feed is already associated with the folder.
#
# It inherits from StandardError, implements no new methods or attributes.
#
# It's normally raised from Folder.associate() and captured in FoldersController.update, which returns an
# HTTP 304 response.

class AlreadyInFolderError < StandardError
end