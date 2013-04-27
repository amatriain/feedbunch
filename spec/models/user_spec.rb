require 'spec_helper'

describe User do
  before :each do
    @user = FactoryGirl.create :user
  end

  it 'returns feeds the user is suscribed to' do
    feed1 = FactoryGirl.create :feed
    feed2 = FactoryGirl.create :feed
    @user.feeds << feed1 << feed2
    @user.feeds.include?(feed1).should be_true
    @user.feeds.include?(feed2).should be_true
  end

  it 'does not return feeds the user is not suscribed to' do
    feed = FactoryGirl.create :feed
    @user.feeds.include?(feed).should be_false
  end

  it 'does not allow duplicate usernames' do
    user_dupe = FactoryGirl.build :user, email: @user.email
    user_dupe.valid?.should be_false
  end

  it 'deletes folders when deleting a user' do
    folder1 = FactoryGirl.build :folder
    folder2 = FactoryGirl.build :folder
    @user.folders << folder1 << folder2

    Folder.count.should eq 2

    @user.destroy
    Folder.count.should eq 0
  end

  it 'retrieves all entries for all subscribed feeds' do
    feed1 = FactoryGirl.create :feed
    feed2 = FactoryGirl.create :feed
    @user.feeds << feed1 << feed2
    entry1 = FactoryGirl.build :entry, feed_id: feed1.id
    entry2 = FactoryGirl.build :entry, feed_id: feed1.id
    entry3 = FactoryGirl.build :entry, feed_id: feed2.id
    feed1.entries << entry1 << entry2
    feed2.entries << entry3

    @user.entries.count.should eq 3
    @user.entries.should include entry1
    @user.entries.should include entry2
    @user.entries.should include entry3
  end
end
