require 'spec_helper'

describe Entry do

  before :each do
    @entry = FactoryGirl.create :entry
  end

  context 'validations' do

    it 'always belongs to a feed' do
      entry = FactoryGirl.build :entry, feed_id: nil
      entry.should_not be_valid
    end

    it 'requires a title' do
      entry_nil = FactoryGirl.build :entry, title: nil
      entry_nil.should_not be_valid
      entry_empty = FactoryGirl.build :entry, title: ''
      entry_empty.should_not be_valid
    end

    it 'requires a URL' do
      entry_nil = FactoryGirl.build :entry, url: nil
      entry_nil.should_not be_valid
      entry_empty = FactoryGirl.build :entry, url: ''
      entry_empty.should_not be_valid
    end

    it 'accepts valid URLs' do
      entry = FactoryGirl.build :entry, url: 'http://xkcd.com'
      entry.should be_valid
    end

    it 'does not accept invalid URLs' do
      entry = FactoryGirl.build :entry, url: 'not-a-url'
      entry.should_not be_valid
    end

    it 'requires a guid' do
      entry_nil = FactoryGirl.build :entry, guid: nil
      entry_nil.should_not be_valid
      entry_empty = FactoryGirl.build :entry, guid: ''
      entry_empty.should_not be_valid
    end

    it 'does not accept duplicate guids' do
      entry_dupe = FactoryGirl.build :entry, guid: @entry.guid
      entry_dupe.should_not be_valid
    end
  end

  context 'sanitization' do

    it 'sanitizes title' do
      unsanitized_title = '<script>alert("pwned!");</script>title'
      sanitized_title = 'title'
      entry = FactoryGirl.create :entry, title: unsanitized_title
      entry.title.should eq sanitized_title
    end

    it 'sanitizes url' do
      unsanitized_url = 'http://xkcd.com<script>alert("pwned!");</script>'
      sanitized_url = 'http://xkcd.com'
      entry = FactoryGirl.create :entry, url: unsanitized_url
      entry.url.should eq sanitized_url
    end

    it 'sanitizes author' do
      unsanitized_author = '<script>alert("pwned!");</script>author'
      sanitized_author = 'author'
      entry = FactoryGirl.create :entry, author: unsanitized_author
      entry.author.should eq sanitized_author
    end

    it 'sanitizes content' do
      unsanitized_content = '<script>alert("pwned!");</script>content'
      sanitized_content = 'content'
      entry = FactoryGirl.create :entry, content: unsanitized_content
      entry.content.should eq sanitized_content
    end

    it 'sanitizes summary' do
      unsanitized_summary = '<script>alert("pwned!");</script>summary'
      sanitized_summary = 'summary'
      entry = FactoryGirl.create :entry, summary: unsanitized_summary
      entry.summary.should eq sanitized_summary
    end

    it 'sanitizes guid' do
      unsanitized_guid = '<script>alert("pwned!");</script>guid'
      sanitized_guid = 'guid'
      entry = FactoryGirl.create :entry, guid: unsanitized_guid
      entry.guid.should eq sanitized_guid
    end
  end

  context 'read/unread state' do

    it 'retrieves the read/unread states of an entry for subscribed users' do
      entry_state1 = FactoryGirl.build :entry_state, entry_id: @entry.id
      entry_state2 = FactoryGirl.build :entry_state, entry_id: @entry.id
      @entry.entry_states << entry_state1 << entry_state2

      @entry.entry_states.count.should eq 2
      @entry.entry_states.should include entry_state1
      @entry.entry_states.should include entry_state2
    end

    it 'deletes entry states when deleting an entry' do
      entry_state1 = FactoryGirl.build :entry_state, entry_id: @entry.id
      entry_state2 = FactoryGirl.build :entry_state, entry_id: @entry.id
      @entry.entry_states << entry_state1 << entry_state2

      EntryState.all.count.should eq 2
      @entry.destroy
      EntryState.all.count.should eq 0
    end

    it 'does not allow duplicate entry states' do
      entry_state = FactoryGirl.build :entry_state, entry_id: @entry.id
      @entry.entry_states << entry_state
      @entry.entry_states << entry_state

      @entry.entry_states.count.should eq 1
    end

    it 'marks an entry as unread for all subscribed users when first saving it' do
      feed = FactoryGirl.create :feed
      user1 = FactoryGirl.create :user
      user2 = FactoryGirl.create :user
      user1.feeds << feed
      user2.feeds << feed

      entry = FactoryGirl.build :entry, feed_id: feed.id
      entry.save!

      user1.entry_states.count.should eq 1
      user1.entry_states.where(entry_id: entry.id, read: false).should be_present
      user2.entry_states.count.should eq 1
      user2.entry_states.where(entry_id: entry.id, read: false).should be_present
    end

    it 'does not change read/unread state when updating an already saved entry' do
      feed = FactoryGirl.create :feed
      entry = FactoryGirl.create :entry, feed_id: feed.id
      user1 = FactoryGirl.create :user
      user2 = FactoryGirl.create :user
      user1.feeds << feed
      user2.feeds << feed

      user1.entry_states.count.should eq 1
      user2.entry_states.count.should eq 1

      entry.summary = "changed summary"
      entry.save!

      user1.entry_states.count.should eq 1
      user2.entry_states.count.should eq 1
    end

    it 'does not save read/unread information for unsubscribed users' do
      feed = FactoryGirl.create :feed
      user1 = FactoryGirl.create :user
      user2 = FactoryGirl.create :user
      user1.feeds << feed

      entry = FactoryGirl.build :entry, feed_id: feed.id
      entry.save!

      user1.entry_states.count.should eq 1
      user1.entry_states.where(entry_id: entry.id, read: false).should be_present
      user2.entry_states.count.should eq 0
    end
  end
end
