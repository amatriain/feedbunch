require 'rails_helper'

describe User, type: :model do

  before :each do
    @user = FactoryGirl.create :user
    @old_subscriptions_updated_at = @user.subscriptions_updated_at
  end

  context 'touches subscriptions' do

    it 'when subscribed to a new feed' do
      feed = FactoryGirl.create :feed
      @user.subscribe feed.fetch_url
      expect(@user.reload.subscriptions_updated_at).to be > @old_subscriptions_updated_at
    end

    context 'changes to subscribed feeed' do

      before :each do
        @feed = FactoryGirl.create :feed
        @user.subscribe @feed.fetch_url
        @old_subscriptions_updated_at = @user.reload.subscriptions_updated_at
      end

      it 'when unsubscribed from a feed' do
        @user.unsubscribe @feed
        expect(@user.reload.subscriptions_updated_at).to be > @old_subscriptions_updated_at
      end

      it 'when feed title changes' do
        @feed.reload.update title: 'another title'
        expect(@user.reload.subscriptions_updated_at).to be > @old_subscriptions_updated_at
      end

      it 'when feed URL changes' do
        @feed.reload.update url: 'http://another.url.com'
        expect(@user.reload.subscriptions_updated_at).to be > @old_subscriptions_updated_at
      end

      context 'unread entries count' do

        before :each do
          @entry1 = FactoryGirl.build :entry, feed_id: @feed.id
          @feed.entries << @entry1
          SubscriptionsManager.recalculate_unread_count @feed, @user
          expect(@user.feed_unread_count @feed).to eq 1
          @old_subscriptions_updated_at = @user.reload.subscriptions_updated_at
        end

        it 'when adding a new entry' do
          entry2 = FactoryGirl.build :entry, feed_id: @feed.id
          @feed.entries << entry2
          SubscriptionsManager.recalculate_unread_count @feed, @user
          expect(@user.feed_unread_count @feed).to eq 2
          expect(@user.reload.subscriptions_updated_at).to be > @old_subscriptions_updated_at
        end

        it 'when marking an entry as unread' do
          entry2 = FactoryGirl.build :entry, feed_id: @feed.id
          @feed.entries << entry2
          @user.change_entries_state entry2, 'read'
          SubscriptionsManager.recalculate_unread_count @feed, @user
          expect(@user.feed_unread_count @feed).to eq 1

          @old_subscriptions_updated_at = @user.reload.subscriptions_updated_at
          @user.change_entries_state entry2, 'unread'
          expect(@user.feed_unread_count @feed).to eq 2
          expect(@user.reload.subscriptions_updated_at).to be > @old_subscriptions_updated_at
        end

        it 'when deleting an entry' do
          entry2 = FactoryGirl.build :entry, feed_id: @feed.id
          @feed.entries << entry2
          SubscriptionsManager.recalculate_unread_count @feed, @user
          expect(@user.feed_unread_count @feed).to eq 2

          @old_subscriptions_updated_at = @user.reload.subscriptions_updated_at
          entry2.destroy
          SubscriptionsManager.recalculate_unread_count @feed, @user
          expect(@user.feed_unread_count @feed).to eq 1
          expect(@user.reload.subscriptions_updated_at).to be > @old_subscriptions_updated_at
        end

        it 'when marking an entry as read' do
          entry2 = FactoryGirl.build :entry, feed_id: @feed.id
          @feed.entries << entry2
          SubscriptionsManager.recalculate_unread_count @feed, @user
          expect(@user.feed_unread_count @feed).to eq 2

          @old_subscriptions_updated_at = @user.reload.subscriptions_updated_at
          @user.change_entries_state entry2, 'read'
          expect(@user.feed_unread_count @feed).to eq 1
          expect(@user.reload.subscriptions_updated_at).to be > @old_subscriptions_updated_at
        end

        it 'when marking all entries as read' do
          entry2 = FactoryGirl.build :entry, feed_id: @feed.id
          @feed.entries << entry2
          SubscriptionsManager.recalculate_unread_count @feed, @user
          expect(@user.feed_unread_count @feed).to eq 2

          @old_subscriptions_updated_at = @user.reload.subscriptions_updated_at
          @user.change_entries_state entry2, 'read', all_entries: true
          SubscriptionsManager.recalculate_unread_count @feed, @user
          expect(@user.feed_unread_count @feed).to eq 0
          expect(@user.reload.subscriptions_updated_at).to be > @old_subscriptions_updated_at
        end

        it 'when marking all entries in a feed as read' do
          entry2 = FactoryGirl.build :entry, feed_id: @feed.id
          @feed.entries << entry2
          SubscriptionsManager.recalculate_unread_count @feed, @user
          expect(@user.feed_unread_count @feed).to eq 2

          @old_subscriptions_updated_at = @user.reload.subscriptions_updated_at
          @user.change_entries_state entry2, 'read', whole_feed: true
          SubscriptionsManager.recalculate_unread_count @feed, @user
          expect(@user.feed_unread_count @feed).to eq 0
          expect(@user.reload.subscriptions_updated_at).to be > @old_subscriptions_updated_at
        end

        it 'when marking all entries in a folder as read' do
          entry2 = FactoryGirl.build :entry, feed_id: @feed.id
          @feed.entries << entry2
          folder = FactoryGirl.build :folder, user_id: @user.id
          @user.folders << folder
          folder.feeds << @feed
          SubscriptionsManager.recalculate_unread_count @feed, @user
          expect(@user.feed_unread_count @feed).to eq 2

          @old_subscriptions_updated_at = @user.reload.subscriptions_updated_at
          @user.change_entries_state entry2, 'read',whole_folder: true
          SubscriptionsManager.recalculate_unread_count @feed, @user
          expect(@user.feed_unread_count @feed).to eq 0
          expect(@user.reload.subscriptions_updated_at).to be > @old_subscriptions_updated_at
        end
      end

      context 'folder changes' do

        it 'when feed is moved into a folder' do
          folder = FactoryGirl.build :folder, user_id: @user.id
          folder.feeds << @feed
          expect(@user.reload.subscriptions_updated_at).to be > @old_subscriptions_updated_at
        end

        it 'when feed is moved out of a folder' do
          folder = FactoryGirl.build :folder, user_id: @user.id
          @user.folders << folder
          folder.feeds << @feed
          @old_subscriptions_updated_at = @user.reload.subscriptions_updated_at

          @feed.remove_from_folder @user
          expect(@user.reload.subscriptions_updated_at).to be > @old_subscriptions_updated_at
        end
      end
    end

  end
end