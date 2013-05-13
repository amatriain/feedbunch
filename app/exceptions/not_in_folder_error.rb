## Error raised when a user tries to remove a feed from a folder, when the feed is not in the folder.
#
# It inherits from StandardError, implements no new methods or attributes.
#
# It's normally raised from Folder.remove_feed() and captured in FoldersController.destroy, which returns an
# HTTP 304 response.

class NotInFolderError < StandardError
end