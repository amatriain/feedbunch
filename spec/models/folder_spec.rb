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

    it 'gives a default value of zero to the unread entries count' do
      folder = FactoryGirl.build :folder, unread_entries: nil
      folder.save!
      folder.unread_entries.should eq 0
    end

    it 'does not accept decimal unread_entries count' do
      folder = FactoryGirl.build :folder, unread_entries: 1.5
      folder.should_not be_valid
    end

    it 'does not accept negative unread_entries count' do
      folder = FactoryGirl.build :folder, unread_entries: -1
      folder.should_not be_valid
    end
  end

  context 'association with feeds' do

    before :each do
      @feed1 = FactoryGirl.create :feed
      @feed2 = FactoryGirl.create :feed
      @feed3 = FactoryGirl.create :feed
      @user.subscribe @feed1.fetch_url
      @user.subscribe @feed2.fetch_url
      @user.subscribe @feed3.fetch_url
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
      # user has two folders, each one with a feed. He's also subscribed to a feed that isn't in any folder
      user = FactoryGirl.create :user
      feed = FactoryGirl.create :feed
      feed2 = FactoryGirl.create :feed
      feed3 = FactoryGirl.create :feed
      folder1 = FactoryGirl.build :folder, user_id: user.id
      folder2 = FactoryGirl.build :folder, user_id: user.id
      user.folders << folder1 << folder2
      user.subscribe feed.fetch_url
      user.subscribe feed2.fetch_url
      user.subscribe feed3.fetch_url
      folder1.feeds << feed2
      folder2.feeds << feed3

      folder1.feeds << feed

      folder1.reload.feeds.should include feed
      folder2.reload.feeds.should_not include feed

      folder2.feeds << feed

      folder1.reload.feeds.should_not include feed
      folder2.reload.feeds.should include feed
    end

    context 'add feed to folder' do

      it 'removes feed from any folders from the same user when associating with the new folder' do
        folder2 = FactoryGirl.build :folder, user_id: @user.id
        @user.folders << folder2
        feed2 = FactoryGirl.create :feed
        @user.subscribe feed2.fetch_url
        @folder.feeds << feed2

        @folder.feeds.should include @feed1

        folder2.feeds << @feed1

        @folder.reload
        @folder.feeds.should_not include @feed1
        folder2.feeds.should include @feed1
      end

      it 'does not change feed association with folders for other users' do
        # folder2 is owned by @user
        folder2 = FactoryGirl.build :folder, user_id: @user.id
        @user.folders << folder2

        # @user has @feed1 in @folder; user2 has @feed1 in folder3
        user2 = FactoryGirl.create :user
        folder3 = FactoryGirl.build :folder, user_id: user2.id
        user2.folders << folder3
        user2.subscribe @feed1.fetch_url
        folder3.feeds << @feed1

        @folder.user_id.should eq @user.id
        @folder.feeds.should include @feed1
        folder2.user_id.should eq @user.id
        folder2.feeds.should_not include @feed1
        folder3.user_id.should eq user2.id
        folder3.feeds.should include @feed1

        folder2.feeds << @feed1
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

      it 'deletes old folder only if it has no more feeds' do
        # @feed3 is in folder2 is owned by @user
        folder2 = FactoryGirl.build :folder, user_id: @user.id
        @user.folders << folder2

        # Move @feed1 from @folder to folder2. @folder1 should not be deleted because @feed2 is still in it
        folder2.feeds << @feed1
        Folder.where(id: @folder.id).should_not be_blank

        # Move @feed1 from folder2 to @folder. folder should be deleted because it has no more feeds
        @folder.feeds << @feed1
        Folder.where(id: folder2.id).should be_blank
      end

      it 'increments the unread entries count when adding a feed' do
        entry1 = FactoryGirl.build :entry, feed_id: @feed1.id
        entry2 = FactoryGirl.build :entry, feed_id: @feed1.id
        @feed1.entries << entry1 << entry2
        @user.change_entry_state [entry1.id], 'read'
        folder2 = FactoryGirl.build :folder, user_id: @user.id
        @user.folders << folder2

        folder2.reload.unread_entries.should eq 0

        folder2.feeds << @feed1

        folder2.reload.unread_entries.should eq 1
      end
    end

    context 'remove feed from folder' do

      it 'removes feed from folder' do
        @folder.feeds.delete @feed1
        @folder.reload
        @folder.feeds.should_not include @feed1
      end

      it 'deletes folder if there are no more feeds in it' do
        @folder.feeds.delete @feed2
        @folder.feeds.count.should eq 1
        @folder.feeds.should include @feed1

        @folder.feeds.delete @feed1

        expect {Folder.find @folder.id}.to raise_error ActiveRecord::RecordNotFound
      end

      it 'does not change feed association with other folders' do
        folder2 = FactoryGirl.create :folder
        folder2.user.subscribe @feed1.fetch_url
        folder2.feeds << @feed1

        @folder.feeds.delete @feed1

        @folder.reload
        @folder.feeds.should_not include @feed1
        folder2.feeds.should include @feed1
      end

      it 'decrements the unread entries count when removing a feed' do
        entry1 = FactoryGirl.build :entry, feed_id: @feed1.id
        entry2 = FactoryGirl.build :entry, feed_id: @feed1.id
        @feed1.entries << entry1 << entry2
        @user.change_entry_state [entry1.id], 'read'
        folder2 = FactoryGirl.build :folder, user_id: @user.id
        @user.folders << folder2
        folder2.feeds << @feed1 << @feed2

        folder2.reload.unread_entries.should eq 1

        folder2.feeds.delete @feed1

        folder2.reload.unread_entries.should eq 0
      end

    end
  end

  context 'association with entries' do
    it 'retrieves all entries for all feeds in a folder' do
      feed1 = FactoryGirl.create :feed
      feed2 = FactoryGirl.create :feed
      @user.subscribe feed1.fetch_url
      @user.subscribe feed2.fetch_url
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

end
