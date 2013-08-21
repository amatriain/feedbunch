require 'spec_helper'

describe User do
  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @user.subscribe @feed.fetch_url
    @entry = FactoryGirl.build :entry, feed_id: @feed.id
    @feed.entries << @entry
  end

  context 'change entry state' do

    it 'marks entry as read' do
      entry_state = EntryState.where(user_id: @user.id, entry_id: @entry.id).first
      entry_state.read.should be_false

      @user.change_entries_state [@entry], 'read'
      entry_state.reload
      entry_state.read.should be_true
    end

    it 'returns changed feeds and folders' do
      folder= FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder
      folder.feeds << @feed

      changed_data = @user.change_entries_state [@entry], 'read'

      changed_data[:feeds].length.should eq 1
      changed_data[:feeds][0].should eq @feed

      changed_data[:folders].length.should eq 1
      changed_data[:folders][0].should eq folder
    end

    it 'marks entry as unread' do
      entry_state = EntryState.where(user_id: @user.id, entry_id: @entry.id).first
      entry_state.read = true
      entry_state.save

      @user.change_entries_state [@entry], 'unread'
      entry_state.reload
      entry_state.read.should be_false
    end

    it 'marks several entries as read' do
      entry2 = FactoryGirl.build :entry, feed_id: @feed.id
      @feed.entries << entry2

      entry_state1 = EntryState.where(user_id: @user.id, entry_id: @entry.id).first
      entry_state1.read.should be_false
      entry_state2 = EntryState.where(user_id: @user.id, entry_id: entry2.id).first
      entry_state2.read.should be_false

      @user.change_entries_state [@entry, entry2], 'read'
      entry_state1.reload
      entry_state1.read.should be_true
      entry_state2.reload
      entry_state2.read.should be_true
    end

    it 'marks several entries as unread' do
      entry2 = FactoryGirl.build :entry, feed_id: @feed.id
      @feed.entries << entry2

      entry_state1 = EntryState.where(user_id: @user.id, entry_id: @entry.id).first
      entry_state1.read = true
      entry_state1.save
      entry_state2 = EntryState.where(user_id: @user.id, entry_id: entry2.id).first
      entry_state2.read = true
      entry_state2.save

      @user.change_entries_state [@entry, entry2], 'unread'
      entry_state1.reload
      entry_state1.read.should be_false
      entry_state2.reload
      entry_state2.read.should be_false
    end

    it 'does not change an entry state if passed an unknown state' do
      entry_state = EntryState.where(user_id: @user.id, entry_id: @entry.id).first
      entry_state.read.should be_false

      @user.change_entries_state [@entry], 'somethingsomethingsomething'
      entry_state.reload
      entry_state.read.should be_false

      entry_state.read = true
      entry_state.save

      @user.change_entries_state [@entry], 'somethingsomethingsomething'
      entry_state.reload
      entry_state.read.should be_true
    end

    it 'does not change state for other users' do
      user2 = FactoryGirl.create :user
      user2.subscribe @feed.fetch_url

      @user.change_entries_state [@entry], 'read'

      entry_state2 = EntryState.where(user_id: user2.id, entry_id: @entry.id).first
      entry_state2.read.should be false
    end
  end

end
