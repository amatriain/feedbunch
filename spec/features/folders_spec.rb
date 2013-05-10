require 'spec_helper'

describe 'folders and feeds' do

  before :each do
    # Ensure no actual HTTP calls are made
    RestClient.stub get: true

    @user = FactoryGirl.create :user

    @folder1 = FactoryGirl.build :folder, user_id: @user.id
    @folder2 = FactoryGirl.create :folder
    @user.folders << @folder1

    @feed1 = FactoryGirl.build :feed
    @feed2 = FactoryGirl.build :feed
    @user.feeds << @feed1 << @feed2
    @folder1.feeds << @feed1

    @entry1_1 = FactoryGirl.build :entry, feed_id: @feed1.id
    @entry1_2 = FactoryGirl.build :entry, feed_id: @feed1.id
    @entry2_1 = FactoryGirl.build :entry, feed_id: @feed2.id
    @entry2_2 = FactoryGirl.build :entry, feed_id: @feed2.id
    @feed1.entries << @entry1_1 << @entry1_2
    @feed2.entries << @entry2_1 << @entry2_2

    login_user_for_feature @user
    visit feeds_path
  end

  it 'shows only folders that belong to the user' do
    page.should have_content @folder1.title
    page.should_not have_content @folder2.title
  end

  it 'shows an All Subscriptions folder with all feeds subscribed to', js: true do
    within 'ul#sidebar' do
      page.should have_content 'All subscriptions'

      within 'li#folder-all' do
        page.should have_css "a[data-target='#feeds-all']"

        # "All feeds" folder should be closed (class "in" not present)
        page.should_not have_css 'ul#feeds-all.in'

        # Open "All feeds" folder (should acquire class "in")
        find("a[data-target='#feeds-all']").click
        page.should have_css 'ul#feeds-all.in'

        # Should have all the feeds inside
        within 'ul#feeds-all' do
          page.should have_css "ul#sidebar li > a[data-feed-id='#{@feed1.id}']"
          page.should have_css "ul#sidebar li > a[data-feed-id='#{@feed2.id}']"
        end
      end
    end
  end

  it 'shows folders containing their respective feeds', js: true do
    within 'ul#sidebar' do
      page.should have_content @folder1.title

      within "li#folder-#{@folder1.id}" do
        page.should have_css "a[data-target='#feeds-#{@folder1.id}']"

        # Folder should be closed (class "in" not present)
        page.should_not have_css "ul#feeds-#{@folder1.id}.in"

        # Open folder (should acquire class "in")
        find("a[data-target='#feeds-#{@folder1.id}']").click
        page.should have_css "ul#feeds-#{@folder1.id}.in"

        # Should have inside only those feeds associated to the folder
        within "ul#feeds-#{@folder1.id}" do
          page.should have_css "ul#sidebar li > a[data-feed-id='#{@feed1.id}']"
          page.should_not have_css "ul#sidebar li > a[data-feed-id='#{@feed2.id}']"
        end
      end
    end
  end

  context 'folder management' do

    before :each do
      read_feed @feed1.id
    end

    it 'hides folder management button until a feed is selected', js: true do
      visit feeds_path
      page.should have_css 'a#folder-management.hidden', visible: false
    end

    it 'shows folder management button when a feed is selected', js: true do
      page.should_not have_css 'a#folder-management.hidden', visible: false
      page.should_not have_css 'a#folder-management.disabled', visible: false
      page.should have_css 'a#folder-management'
    end

    it 'hides folder management button when reading a whole folder', js: true do
      read_feed 'all'
      sleep 1
      page.should have_css 'a#folder-management.hidden', visible: false
      page.should have_css 'a#folder-management.disabled', visible: false
      page.should_not have_css 'a#folder-management'
    end

    it 'drops down a list of all user folders', js: true do
      find('#folder-management').click
      within '#folder-management-dropdown' do
        page.should have_content @folder1.title
      end
    end

    it 'has No Folder and New Folder links in the dropdown', js: true do
      find('#folder-management').click
      within '#folder-management-dropdown' do
        page.should have_css 'li[data-folder-id="none"]'
        page.should have_css "li[data-folder-id='#{@folder1.id}']"
      end
    end

    it 'shows a tick besides No Folder when the feed is not in a folder', js: true do
      read_feed @feed2.id
      find('#folder-management').click
      within '#folder-management-dropdown' do
        # tick should be only besides No Folder
        page.should have_css 'li[data-folder-id="none"] a > i.icon-ok'
        page.should_not have_css "li[data-folder-id='#{@folder1.id}'] a > i.icon-ok"
      end
    end

    it 'shows a tick besides the folder name when the feed is in a folder', js: true do
      find('#folder-management').click
      within '#folder-management-dropdown' do
        # tick should be only besides @folder1
        page.should_not have_css 'li[data-folder-id="none"] a > i.icon-ok'
        page.should have_css "li[data-folder-id='#{@folder1.id}'] a > i.icon-ok"
      end
    end

    it 'adds a feed to a new folder'

    it 'adds a feed to an existing folder'

    it 'removes a feed from a folder'

    it 'totally removes a folder when it has no feeds under it'
  end

end