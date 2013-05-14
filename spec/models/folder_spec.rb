require 'spec_helper'

describe Folder do
  before :each do
    @user = FactoryGirl.create :user
    @folder = FactoryGirl.build :folder, user_id: @user.id
    @user.folders << @folder
    @folder.reload
  end

  context 'validations' do
    it 'always belongs to a user' do
      folder = FactoryGirl.build :folder, user_id: nil
      folder.should_not be_valid
    end

    it 'requires a title' do
      folder_nil = FactoryGirl.build :folder, title: nil
      folder_nil.should_not be_valid

      folder_empty = FactoryGirl.build :folder, title: ''
      folder_empty.should_not be_valid
    end

    it 'does not accept duplicate titles for the same user' do
      folder_dupe = FactoryGirl.build :folder, user_id: @folder.user_id, title: @folder.title
      folder_dupe.should_not be_valid
    end

    it 'accepts duplicate titles for different users' do
      folder_dupe = FactoryGirl.build :folder, title: @folder.title
      folder_dupe.user_id.should_not eq @folder.user_id
      folder_dupe.should be_valid
    end
  end

  context 'association with feeds' do

    before :each do
      @feed1 = FactoryGirl.create :feed
      @feed2 = FactoryGirl.create :feed
      @feed3 = FactoryGirl.create :feed
      @user.feeds << @feed1 << @feed2 << @feed3
      @folder.feeds << @feed1 << @feed2
    end

    it 'returns feeds associated with this folder' do
      @folder.feeds.should include @feed1
      @folder.feeds.should include @feed2
    end

    it 'does not return feeds not associated with this folder' do
      @folder.feeds.should_not include @feed3
    end

    it 'does not allow associating the same feed more than once' do
      @folder.feeds.count.should eq 2
      @folder.feeds.where(id: @feed1.id).count.should eq 1

      @folder.feeds << @feed1
      @folder.feeds.count.should eq 2
      @folder.feeds.where(id: @feed1.id).count.should eq 1
    end

    it 'allows associating a feed with at most one folder for a single user' do
      user = FactoryGirl.create :user
      feed = FactoryGirl.create :feed
      folder1 = FactoryGirl.build :folder, user_id: user.id
      folder2 = FactoryGirl.build :folder, user_id: user.id
      user.folders << folder1 << folder2

      folder1.feeds << feed
      feed.reload
      folder2.feeds << feed

      folder1.feeds.should include feed
      folder2.feeds.should_not include feed
    end

    context 'add feed to folder' do

      it 'returns the updated folder' do
        out = Folder.add_feed @folder.id, @feed3.id
        out.should eq @folder
      end

      it 'associates a feed with a folder' do
        Folder.add_feed @folder.id, @feed3.id
        @folder.feeds.should include @feed3
      end

      it 'raises an error if the feed is already associated with the folder' do
        expect {Folder.add_feed @folder.id, @feed1.id}.to raise_error AlreadyInFolderError
      end

      it 'removes feed from any folders from the same user when associating with the new folder' do
        folder2 = FactoryGirl.build :folder, user_id: @user.id
        @user.folders << folder2

        @folder.feeds.should include @feed1
        Folder.add_feed folder2.id, @feed1.id
        @folder.reload
        @folder.feeds.should_not include @feed1
        folder2.feeds.should include @feed1
      end

      it 'does not change feed association with folders for other users' do
        # Empty folder folder3 belonging to @user
        folder2 = FactoryGirl.build :folder, user_id: @user.id
        @user.folders << folder2

        # @user has @feed1 in @folder; user2 has @feed1 in folder2
        user2 = FactoryGirl.create :user
        folder3 = FactoryGirl.build :folder, user_id: user2.id
        user2.folders << folder3
        folder3.feeds << @feed1

        @folder.user_id.should eq @user.id
        @folder.feeds.should include @feed1
        folder2.user_id.should eq @user.id
        folder2.feeds.should_not include @feed1
        folder3.user_id.should eq user2.id
        folder3.feeds.should include @feed1

        Folder.add_feed folder2.id, @feed1.id
        @folder.reload
        folder2.reload
        folder3.reload

        @folder.user_id.should eq @user.id
        @folder.feeds.should_not include @feed1
        folder2.user_id.should eq @user.id
        folder2.feeds.should include @feed1
        folder3.user_id.should eq user2.id
        folder3.feeds.should include @feed1
      end
    end

    context 'remove feed from folder' do

      it 'removes feed from folder' do
        Folder.remove_feed @folder.id, @feed1.id
        @folder.reload
        @folder.feeds.should_not include @feed1
      end

      it 'returns true if there are more feeds in the folder' do
        out = Folder.remove_feed @folder.id, @feed1.id
        out.should be_true
      end

      it 'returns false if there are no more feeds in the folder' do
        @folder.feeds.delete @feed2
        @folder.feeds.count.should eq 1
        @folder.feeds.should include @feed1

        out = Folder.remove_feed @folder.id, @feed1.id
        out.should be_false
      end

      it 'deletes folder if there are no more feeds in it' do
        @folder.feeds.delete @feed2
        @folder.feeds.count.should eq 1
        @folder.feeds.should include @feed1

        Folder.remove_feed @folder.id, @feed1.id

        expect {Folder.find @folder.id}.to raise_error ActiveRecord::RecordNotFound
      end

      it 'raises an error if the feed is not in the folder' do
        expect {Folder.remove_feed @folder.id, @feed3.id}.to raise_error NotInFolderError
      end

      it 'does not change feed association with other folders' do
        folder2 = FactoryGirl.create :folder
        folder2.feeds << @feed1

        Folder.remove_feed @folder.id, @feed1.id

        @folder.reload
        @folder.feeds.should_not include @feed1
        folder2.feeds.should include @feed1
      end

    end
  end

  context 'association with entries' do
    it 'retrieves all entries for all feeds in a folder' do
      feed1 = FactoryGirl.create :feed
      feed2 = FactoryGirl.create :feed
      @folder.feeds << feed1 << feed2
      entry1 = FactoryGirl.build :entry, feed_id: feed1.id
      entry2 = FactoryGirl.build :entry, feed_id: feed1.id
      entry3 = FactoryGirl.build :entry, feed_id: feed2.id
      feed1.entries << entry1 << entry2
      feed2.entries << entry3

      @folder.entries.count.should eq 3
      @folder.entries.should include entry1
      @folder.entries.should include entry2
      @folder.entries.should include entry3
    end
  end

  context 'sanitization' do
    it 'sanitizes title' do
      title_unsanitized = '<script>alert("pwned!");</script>folder_title'
      title_sanitized = 'folder_title'
      folder = FactoryGirl.create :folder, title: title_unsanitized
      folder.title.should eq title_sanitized
    end
  end

  context 'create folder for user' do

    it 'creates folder for the specified user' do
      title = 'New folder'
      Folder.create_user_folder title, @user.id

      @user.reload
      @user.folders.where(title: title).should_not be_blank
    end

    it 'returns the new folder' do
      title = 'New folder'
      folder = Folder.create_user_folder title, @user.id
      folder.title.should eq title
      @user.folders.should include folder
    end

    it 'raises an error if the user already has a folder with the same title' do
      expect {Folder.create_user_folder @folder.title, @user.id}.to raise_error FolderAlreadyExistsError
    end

    it 'does not raise an error if another user has a folder with the same title' do
      user2 = FactoryGirl.create :user
      folder2 = FactoryGirl.build :folder, user_id: user2.id
      user2.folders << folder2

      expect {Folder.create_user_folder folder2.title, @user.id}.to_not raise_error
    end
  end
end
