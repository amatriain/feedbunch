## Error raised when a user tries to create a new folder with the same title as another of his folders.
#
# It inherits from StandardError, implements no new methods or attributes.
#
# It's normally raised from Folder.create_user_folder() and captured in FoldersController.create, which returns an
# HTTP 304 response.

class FolderAlreadyExistsError < StandardError
end