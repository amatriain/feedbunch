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

    it 'does not accept duplicate guids for the same feed' do
      entry_dupe = FactoryGirl.build :entry, guid: @entry.guid, feed_id: @entry.feed.id
      entry_dupe.should_not be_valid
    end

    it 'does accept duplicate guids for different feeds' do
      feed2 = FactoryGirl.create :feed
      entry_dupe = FactoryGirl.build :entry, guid: @entry.guid, feed_id: feed2.id
      entry_dupe.should be_valid
    end
  end

  context 'default values' do

    before :each do
      @url = 'http://some.feed.com'
    end

    it 'defaults guid to url attribute' do
      entry1 = FactoryGirl.create :entry, url: @url, guid: nil
      entry1.guid.should eq @url

      entry1.destroy

      entry2 = FactoryGirl.create :entry, url: @url, guid: ''
      entry2.guid.should eq @url
    end

    it 'defaults title to url attribute' do
      entry1 = FactoryGirl.create :entry, url: @url, title: nil
      entry1.title.should eq @url

      entry2 = FactoryGirl.create :entry, url: @url, title: ''
      entry2.title.should eq @url
    end

    it 'does not use default value if guid has value' do
      guid = '123456789a'
      entry = FactoryGirl.create :entry, url: @url, guid: guid
      entry.guid.should eq guid
    end

    it 'does not use default value if title has value' do
      title = 'entry_title'
      entry = FactoryGirl.create :entry, url: @url, title: title
      entry.title.should eq title
    end

    it 'defaults url to guid if url is not a valid HTTP URL' do
      entry = FactoryGirl.create :entry, url: 'not a valid url', guid: @url
      entry.guid.should eq @url
      entry.url.should eq @url
    end

    it 'defaults published date to current date' do
      published = DateTime.new 2000, 01, 01
      DateTime.stub(:now).and_return published
      entry = FactoryGirl.create :entry, published: nil
      entry.published.should eq published
    end

    it 'does not use default value if published date has value' do
      published = DateTime.new 2000, 01, 01
      entry = FactoryGirl.create :entry, published: published
      entry.published.should eq published
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
      sanitized_content = '<p>content</p>'
      entry = FactoryGirl.create :entry, content: unsanitized_content
      entry.content.should eq sanitized_content
    end

    it 'sanitizes summary' do
      unsanitized_summary = '<script>alert("pwned!");</script><p>summary</p>'
      sanitized_summary = '<p>summary</p>'
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

  context 'markup manipulation' do

    context 'summary' do

      it 'opens summary links in a new tab' do
        unmodified_summary = '<a href="http://some.link">Click here to read full story</a>'
        modified_summary = '<a href="http://some.link" target="_blank">Click here to read full story</a>'
        entry = FactoryGirl.create :entry, summary: unmodified_summary
        entry.summary.should eq modified_summary
      end

      it 'removes width and height and adds max-width to images' do
        unmodified_summary = '<img width="1000" height="337" alt="20131029" class="attachment-full wp-post-image" src="http://www.leasticoulddo.com/wp-content/uploads/2013/10/20131029.gif">'
        modified_summary = '<img alt="20131029" class="attachment-full wp-post-image" src="http://www.leasticoulddo.com/wp-content/uploads/2013/10/20131029.gif" style="max-width:100%;">'
        entry = FactoryGirl.create :entry, summary: unmodified_summary
        entry.summary.should eq modified_summary
      end
    end

    context 'content' do

      it 'opens content links in a new tab' do
        unmodified_content = '<a href="http://some.link">Click here to read full story</a>'
        modified_content = '<a href="http://some.link" target="_blank">Click here to read full story</a>'
        entry = FactoryGirl.create :entry, content: unmodified_content
        entry.content.should eq modified_content
      end

      it 'removes width and height and adds max-width to images' do
        unmodified_content = '<img width="1000" height="337" alt="20131029" class="attachment-full wp-post-image" src="http://www.leasticoulddo.com/wp-content/uploads/2013/10/20131029.gif">'
        modified_content = '<img alt="20131029" class="attachment-full wp-post-image" src="http://www.leasticoulddo.com/wp-content/uploads/2013/10/20131029.gif" style="max-width:100%;">'
        entry = FactoryGirl.create :entry, content: unmodified_content
        entry.content.should eq modified_content
      end
    end

  end

  context 'read/unread state' do

    it 'stores the read/unread states of an entry for subscribed users' do
      feed = FactoryGirl.create :feed
      entry = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry
      user1 = FactoryGirl.create :user
      user2 = FactoryGirl.create :user
      user1.subscribe feed.fetch_url
      user2.subscribe feed.fetch_url

      entry.entry_states.count.should eq 2
      entry.entry_states.where(user_id: user1.id).count.should eq 1
      entry.entry_states.where(user_id: user2.id).count.should eq 1
    end

    it 'deletes entry states when deleting an entry' do
      feed = FactoryGirl.create :feed
      entry = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry
      user = FactoryGirl.create :user
      user.subscribe feed.fetch_url

      EntryState.where(entry_id: entry.id).count.should eq 1

      entry.destroy
      EntryState.where(entry_id: entry.id).count.should eq 0
    end

    it 'marks an entry as unread for all subscribed users when first saving it' do
      feed = FactoryGirl.create :feed
      user1 = FactoryGirl.create :user
      user2 = FactoryGirl.create :user
      user1.subscribe feed.fetch_url
      user2.subscribe feed.fetch_url

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
      user1.subscribe feed.fetch_url
      user2.subscribe feed.fetch_url

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
      user1.subscribe feed.fetch_url

      entry = FactoryGirl.build :entry, feed_id: feed.id
      entry.save!

      user1.entry_states.count.should eq 1
      user1.entry_states.where(entry_id: entry.id, read: false).should be_present
      user2.entry_states.count.should eq 0
    end

    it 'retrieves state for a read entry' do
      feed = FactoryGirl.create :feed
      user = FactoryGirl.create :user
      user.subscribe feed.fetch_url
      entry = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry

      entry_state = EntryState.where(user_id: user.id, entry_id: entry.id).first
      entry_state.read = true
      entry_state.save

      entry.read_by?(user).should be_true
    end

    it 'retrieves state for an unread entry' do
      feed = FactoryGirl.create :feed
      user = FactoryGirl.create :user
      user.subscribe feed.fetch_url
      entry = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry

      entry_state = EntryState.where(user_id: user.id, entry_id: entry.id).first
      entry_state.read = false
      entry_state.save

      entry.read_by?(user).should be_false
    end

    it 'raises error trying to get state for an entry from an unsubscribed feed' do
      feed = FactoryGirl.create :feed
      user = FactoryGirl.create :user
      entry = FactoryGirl.build :entry, feed_id: feed.id
      feed.entries << entry

      expect {entry.read_by? user}.to raise_error
    end
  end
end
