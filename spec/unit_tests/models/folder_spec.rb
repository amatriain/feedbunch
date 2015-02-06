require 'rails_helper'

describe Folder, type: :model do
  before :each do
    @user = FactoryGirl.create :user
    @folder = FactoryGirl.build :folder, user_id: @user.id
    @user.folders << @folder
    @folder.reload
  end

  context 'validations' do
    it 'always belongs to a user' do
      folder = FactoryGirl.build :folder, user_id: nil
      expect(folder).not_to be_valid
    end

    it 'requires a title' do
      folder_nil = FactoryGirl.build :folder, title: nil
      expect(folder_nil).not_to be_valid

      folder_empty = FactoryGirl.build :folder, title: ''
      expect(folder_empty).not_to be_valid
    end

    it 'does not accept duplicate titles for the same user' do
      folder_dupe = FactoryGirl.build :folder, user_id: @folder.user_id, title: @folder.title
      expect(folder_dupe).not_to be_valid
    end

    it 'accepts duplicate titles for different users' do
      folder_dupe = FactoryGirl.build :folder, title: @folder.title
      expect(folder_dupe.user_id).not_to eq @folder.user_id
      expect(folder_dupe).to be_valid
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
      expect(@folder.feeds).to include @feed1
      expect(@folder.feeds).to include @feed2
    end

    it 'does not return feeds not associated with this folder' do
      expect(@folder.feeds).not_to include @feed3
    end

    it 'does not allow associating the same feed more than once' do
      expect(@folder.feeds.count).to eq 2
      expect(@folder.feeds.where(id: @feed1.id).count).to eq 1

      @folder.feeds << @feed1
      expect(@folder.feeds.count).to eq 2
      expect(@folder.feeds.where(id: @feed1.id).count).to eq 1
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

      expect(folder1.reload.feeds).to include feed
      expect(folder2.reload.feeds).not_to include feed

      folder2.feeds << feed

      expect(folder1.reload.feeds).not_to include feed
      expect(folder2.reload.feeds).to include feed
    end

    context 'add feed to folder' do

      it 'removes feed from any folders from the same user when associating with the new folder' do
        folder2 = FactoryGirl.build :folder, user_id: @user.id
        @user.folders << folder2
        feed2 = FactoryGirl.create :feed
        @user.subscribe feed2.fetch_url
        @folder.feeds << feed2

        expect(@folder.feeds).to include @feed1

        folder2.feeds << @feed1

        @folder.reload
        expect(@folder.feeds).not_to include @feed1
        expect(folder2.feeds).to include @feed1
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

        expect(@folder.user_id).to eq @user.id
        expect(@folder.feeds).to include @feed1
        expect(folder2.user_id).to eq @user.id
        expect(folder2.feeds).not_to include @feed1
        expect(folder3.user_id).to eq user2.id
        expect(folder3.feeds).to include @feed1

        folder2.feeds << @feed1
        @folder.reload
        folder2.reload
        folder3.reload

        expect(@folder.user_id).to eq @user.id
        expect(@folder.feeds).not_to include @feed1
        expect(folder2.user_id).to eq @user.id
        expect(folder2.feeds).to include @feed1
        expect(folder3.user_id).to eq user2.id
        expect(folder3.feeds).to include @feed1
      end

      it 'deletes old folder only if it has no more feeds' do
        # @feed3 is in folder2 is owned by @user
        folder2 = FactoryGirl.build :folder, user_id: @user.id
        @user.folders << folder2

        # Move @feed1 from @folder to folder2. @folder1 should not be deleted because @feed2 is still in it
        folder2.feeds << @feed1
        expect(Folder.where(id: @folder.id)).not_to be_blank

        # Move @feed1 from folder2 to @folder. folder should be deleted because it has no more feeds
        @folder.feeds << @feed1
        expect(Folder.where(id: folder2.id)).to be_blank
      end
    end

    context 'remove feed from folder' do

      it 'removes feed from folder' do
        @folder.feeds.delete @feed1
        @folder.reload
        expect(@folder.feeds).not_to include @feed1
      end

      it 'deletes folder if there are no more feeds in it' do
        @folder.feeds.delete @feed2
        expect(@folder.feeds.count).to eq 1
        expect(@folder.feeds).to include @feed1

        @folder.feeds.delete @feed1

        expect {Folder.find @folder.id}.to raise_error ActiveRecord::RecordNotFound
      end

      it 'does not change feed association with other folders' do
        folder2 = FactoryGirl.create :folder
        folder2.user.subscribe @feed1.fetch_url
        folder2.feeds << @feed1

        @folder.feeds.delete @feed1

        @folder.reload
        expect(@folder.feeds).not_to include @feed1
        expect(folder2.feeds).to include @feed1
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

      expect(@folder.entries.count).to eq 3
      expect(@folder.entries).to include entry1
      expect(@folder.entries).to include entry2
      expect(@folder.entries).to include entry3
    end
  end

  context 'sanitization' do
    it 'sanitizes title' do
      title_unsanitized = '<script>alert("pwned!");</script>folder_title'
      title_sanitized = 'folder_title'
      folder = FactoryGirl.create :folder, title: title_unsanitized
      expect(folder.title).to eq title_sanitized
    end
  end

  context 'subscriptions_updated_at' do

    it 'defaults to the current date/time' do
      now = Time.zone.parse '2000-01-01'
      allow_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return now
      folder = FactoryGirl.build :folder, subscriptions_updated_at: nil
      @user.folders << folder
      expect(folder.reload.subscriptions_updated_at).to eq now
    end

    context 'touches subscriptions' do

      before :each do
        @feed = FactoryGirl.create :feed
        @user.subscribe @feed.fetch_url
        @folder.feeds << @feed
        @old_subscriptions_updated_at = @folder.reload.subscriptions_updated_at
      end

      it 'when unsubscribed from a feed in the folder' do
        # Move a second feed into the folder, so that it is not deleted when unsubscribing from @feed
        feed = FactoryGirl.create :feed
        @user.subscribe feed.fetch_url
        @folder.feeds << feed
        @old_subscriptions_updated_at = @folder.reload.subscriptions_updated_at

        @user.unsubscribe @feed
        expect(@folder.reload.subscriptions_updated_at).not_to eq  @old_subscriptions_updated_at
      end

      it 'when the title of a feed in the folder changes' do
        @feed.reload.update title: 'another title'
        expect(@folder.reload.subscriptions_updated_at).not_to eq  @old_subscriptions_updated_at
      end

      it 'when the URL of a feed in the folder changes' do
        @feed.reload.update url: 'http://another.url.com'
        expect(@folder.reload.subscriptions_updated_at).not_to eq  @old_subscriptions_updated_at
      end

      context 'unread entries count' do

        it 'when adding a new entry to a feed in the folder' do
          entry = FactoryGirl.build :entry, feed_id: @feed.id
          @feed.entries << entry
          SubscriptionsManager.recalculate_unread_count @feed, @user
          expect(@folder.reload.subscriptions_updated_at).not_to eq  @old_subscriptions_updated_at
        end

        it 'when marking an entry of a feed in the folder as unread' do
          entry = FactoryGirl.build :entry, feed_id: @feed.id
          @feed.entries << entry
          @user.change_entries_state entry, 'read'
          @old_subscriptions_updated_at = @folder.reload.subscriptions_updated_at

          @user.change_entries_state entry, 'unread'
          expect(@folder.reload.subscriptions_updated_at).not_to eq  @old_subscriptions_updated_at
        end

        it 'when deleting an entry from a feed in the folder' do
          entry = FactoryGirl.build :entry, feed_id: @feed.id
          @feed.entries << entry
          SubscriptionsManager.recalculate_unread_count @feed, @user
          @old_subscriptions_updated_at = @folder.reload.subscriptions_updated_at

          entry.destroy
          SubscriptionsManager.recalculate_unread_count @feed, @user
          expect(@folder.reload.subscriptions_updated_at).not_to eq  @old_subscriptions_updated_at
        end

        it 'when marking an entry of a feed in the folder as read' do
          entry = FactoryGirl.build :entry, feed_id: @feed.id
          @feed.entries << entry
          SubscriptionsManager.recalculate_unread_count @feed, @user
          @old_subscriptions_updated_at = @folder.reload.subscriptions_updated_at

          @user.change_entries_state entry, 'read'
          expect(@folder.reload.subscriptions_updated_at).not_to eq  @old_subscriptions_updated_at
        end

        it 'when marking all entries as read' do
          entry = FactoryGirl.build :entry, feed_id: @feed.id
          @feed.entries << entry
          SubscriptionsManager.recalculate_unread_count @feed, @user
          @old_subscriptions_updated_at = @folder.reload.subscriptions_updated_at

          @user.change_entries_state entry, 'read', all_entries: true
          SubscriptionsManager.recalculate_unread_count @feed, @user
          expect(@folder.reload.subscriptions_updated_at).not_to eq  @old_subscriptions_updated_at
        end

        it 'when marking all entries in the folder as read' do
          entry = FactoryGirl.build :entry, feed_id: @feed.id
          @feed.entries << entry
          SubscriptionsManager.recalculate_unread_count @feed, @user
          @old_subscriptions_updated_at = @folder.reload.subscriptions_updated_at

          @user.change_entries_state entry, 'read', whole_folder: true
          SubscriptionsManager.recalculate_unread_count @feed, @user
          expect(@folder.reload.subscriptions_updated_at).not_to eq @old_subscriptions_updated_at
        end

        it 'when marking all entries of a feed in the folder as read' do
          entry = FactoryGirl.build :entry, feed_id: @feed.id
          @feed.entries << entry
          SubscriptionsManager.recalculate_unread_count @feed, @user
          @old_subscriptions_updated_at = @folder.reload.subscriptions_updated_at

          @user.change_entries_state entry, 'read', whole_feed: true
          SubscriptionsManager.recalculate_unread_count @feed, @user
          expect(@folder.reload.subscriptions_updated_at).not_to eq @old_subscriptions_updated_at
        end

      end

      context 'moving feeds' do

        it 'when feed is moved into the folder' do
          feed = FactoryGirl.create :feed
          @user.subscribe feed.fetch_url
          @old_subscriptions_updated_at = @folder.reload.subscriptions_updated_at

          @folder.feeds << feed
          expect(@folder.reload.subscriptions_updated_at).not_to eq  @old_subscriptions_updated_at
        end

        it 'when feed is moved out of the folder' do
          # Move a second feed into the folder, so that it is not deleted when unsubscribing from @feed
          feed = FactoryGirl.create :feed
          @user.subscribe feed.fetch_url
          @folder.feeds << feed
          @old_subscriptions_updated_at = @folder.reload.subscriptions_updated_at

          @user.move_feed_to_folder @feed, folder: Folder::NO_FOLDER
          expect(@folder.reload.subscriptions_updated_at).not_to eq  @old_subscriptions_updated_at
        end

      end

    end

    context 'does not touch subscriptions' do

      before :each do
        @feed = FactoryGirl.create :feed
        @user.subscribe @feed.fetch_url
        @old_subscriptions_updated_at = @folder.reload.subscriptions_updated_at
      end

      it 'when unsubscribed from a feed not in the folder' do
        @user.unsubscribe @feed
        expect(@folder.reload.subscriptions_updated_at).to eq  @old_subscriptions_updated_at
      end

      it 'when the title of a feed not in the folder changes' do
        @feed.reload.update title: 'another title'
        expect(@folder.reload.subscriptions_updated_at).to eq  @old_subscriptions_updated_at
      end

      it 'when the URL of a feed not in the folder changes' do
        @feed.reload.update url: 'http://another.url.com'
        expect(@folder.reload.subscriptions_updated_at).to eq  @old_subscriptions_updated_at
      end

      context 'unread entries count' do

        it 'when adding a new entry to a feed not in the folder' do
          entry = FactoryGirl.build :entry, feed_id: @feed.id
          @feed.entries << entry
          SubscriptionsManager.recalculate_unread_count @feed, @user
          expect(@folder.reload.subscriptions_updated_at).to eq  @old_subscriptions_updated_at
        end

        it 'when marking an entry of a feed not in the folder as unread' do
          entry = FactoryGirl.build :entry, feed_id: @feed.id
          @feed.entries << entry
          @user.change_entries_state entry, 'read'
          @subscriptions_updated_at = @folder.reload.subscriptions_updated_at

          @user.change_entries_state entry, 'unread'
          expect(@folder.reload.subscriptions_updated_at).to eq  @old_subscriptions_updated_at
        end

        it 'when deleting an entry from a feed not in the folder' do
          entry = FactoryGirl.build :entry, feed_id: @feed.id
          @feed.entries << entry
          SubscriptionsManager.recalculate_unread_count @feed, @user
          @old_subscriptions_updated_at = @folder.reload.subscriptions_updated_at

          entry.destroy
          SubscriptionsManager.recalculate_unread_count @feed, @user
          expect(@folder.reload.subscriptions_updated_at).to eq  @old_subscriptions_updated_at
        end

        it 'when marking an entry of a feed not in the folder as read' do
          entry = FactoryGirl.build :entry, feed_id: @feed.id
          @feed.entries << entry
          SubscriptionsManager.recalculate_unread_count @feed, @user
          @old_subscriptions_updated_at = @folder.reload.subscriptions_updated_at

          @user.change_entries_state entry, 'read'
          expect(@folder.reload.subscriptions_updated_at).to eq  @old_subscriptions_updated_at
        end

        it 'when marking all entries of a feed not in the folder as read' do
          entry = FactoryGirl.build :entry, feed_id: @feed.id
          @feed.entries << entry
          SubscriptionsManager.recalculate_unread_count @feed, @user
          @old_subscriptions_updated_at = @folder.reload.subscriptions_updated_at

          @user.change_entries_state entry, 'read', whole_feed: true
          SubscriptionsManager.recalculate_unread_count @feed, @user
          expect(@folder.reload.subscriptions_updated_at).to eq  @old_subscriptions_updated_at
        end

      end

    end

  end

end
