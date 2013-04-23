require 'spec_helper'

describe User do
  before :each do
    @user = FactoryGirl.create :user
  end

  it 'returns feeds the user is suscribed to' do
    feed1 = FactoryGirl.build :feed
    feed2 = FactoryGirl.build :feed
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
end
