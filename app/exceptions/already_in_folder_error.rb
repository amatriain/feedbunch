## Error raised when a user tries to add a feed to a folder, when the feed is already in the folder.
#
# It inherits from StandardError, implements no new methods or attributes.
#
# It's normally raised from Folder.add_feed() and captured in FoldersController.update, which returns an
# HTTP 304 response.

class AlreadyInFolderError < StandardError
end