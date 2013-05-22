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
    within '#sidebar' do
      page.should have_content 'All subscriptions'

      within '#folders-list li#folder-all' do
        page.should have_css "a[data-target='#feeds-all']"

        # "All feeds" folder should be open (class "in" present)
        page.should have_css 'ul#feeds-all.in'

        # Should have all the feeds inside
        within 'ul#feeds-all' do
          page.should have_css "a[data-sidebar-feed][data-feed-id='#{@feed1.id}']"
          page.should have_css "a[data-sidebar-feed][data-feed-id='#{@feed2.id}']"
        end
      end
    end
  end

  it 'shows folders containing their respective feeds', js: true do
    within '#sidebar' do
      page.should have_content @folder1.title

      within "#folders-list li#folder-#{@folder1.id}" do
        page.should have_css "a[data-target='#feeds-#{@folder1.id}']"

        # Folder should be open (class "in" present)
        page.should have_css "ul#feeds-#{@folder1.id}.in"

        # Should have inside only those feeds associated to the folder
        within "ul#feeds-#{@folder1.id}" do
          page.should have_css "a[data-sidebar-feed][data-feed-id='#{@feed1.id}']"
          page.should_not have_css "a[data-sidebar-feed][data-feed-id='#{@feed2.id}']"
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
    end

    it 'drops down a list of all user folders', js: true do
      find('#folder-management').click
      within '#folder-management-dropdown ul.dropdown-menu' do
        page.should have_content @folder1.title
      end
    end

    it 'has No Folder and New Folder links in the dropdown', js: true do
      find('#folder-management').click
      within '#folder-management-dropdown' do
        page.should have_css 'a[data-folder-id="none"]'
        page.should have_css 'a[data-folder-id="new"]'
      end
    end

    it 'shows a tick besides No Folder when the feed is not in a folder', js: true do
      read_feed @feed2.id
      find('#folder-management').click
      within '#folder-management-dropdown' do
        # tick should be only besides No Folder
        page.should have_css 'a[data-folder-id="none"] > i.icon-ok'
        page.should_not have_css "li[data-folder-id='#{@folder1.id}'] a > i.icon-ok"
      end
    end

    it 'shows a tick besides the folder name when the feed is in a folder', js: true do
      find('#folder-management').click
      within '#folder-management-dropdown' do
        # tick should be only besides @folder1
        page.should_not have_css 'li[data-folder-id="none"] a > i.icon-ok'
        page.should have_css "a[data-folder-id='#{@folder1.id}'] > i.icon-ok"
      end
    end

    context 'add feed to existing folder' do
      
      before :each do
        @new_folder = FactoryGirl.build :folder, user_id: @user.id
        @user.folders << @new_folder
        visit feeds_path
        read_feed @feed1.id
      end

      it 'adds a feed to an existing folder', js: true do
        read_feed @feed2.id
        sleep 1
        find('#folder-management').click
        sleep 1
        within '#folder-management-dropdown ul.dropdown-menu' do
          # While reading a feed that is not in a folder, click on an existing folder in the dropdown menu
          find("a[data-folder-id='#{@folder1.id}']").click
        end

        # feed under the "all subscriptions" folder in the sidebar should have a data-folder-id attribute that indicates the feed
        # is now inside @folder1
        page.should have_css "#folder-all ul#feeds-all a[data-sidebar-feed][data-feed-id='#{@feed2.id}'][data-folder-id='#{@folder1.id}']", visible: false

        # the feed should have exactly the same link in the sidebar under the @folder1 folder
        page.should have_css "#folder-#{@folder1.id} ul#feeds-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed2.id}'][data-folder-id='#{@folder1.id}']", visible: false
      end

      it 'removes feed from its old folder when adding it to a different one', js: true do
        # User has feeds @feed1, @feed2 in @folder1
        @user.feeds << @feed2
        @folder1.feeds << @feed2

        visit feeds_path
        read_feed @feed1.id

        # @feed1 should be under @folder1
        page.should have_css "li#folder-#{@folder1.id} > ul#feeds-#{@folder1.id} > li > a[data-feed-id='#{@feed1.id}'][data-folder-id='#{@folder1.id}']", visible: false

        find('#folder-management').click
        within '#folder-management-dropdown ul.dropdown-menu' do
          find("a[data-folder-id='#{@new_folder.id}']").click
        end

        # feed under the "all subscriptions" folder in the sidebar should have a data-folder-id attribute that indicates the feed
        # is now inside "@new_folder"
        page.should have_css "li#folder-all > ul#feeds-all > li > a[data-feed-id='#{@feed1.id}'][data-folder-id='#{@new_folder.id}']", visible: false

        # the feed should have exactly the same link in the sidebar under the @new_folder folder
        page.should have_css "li#folder-#{@new_folder.id} > ul#feeds-#{@new_folder.id} > li > a[data-feed-id='#{@feed1.id}'][data-folder-id='#{@new_folder.id}']", visible: false

        # the feed should have disappeared from @folder1
        page.should_not have_css "li#folder-#{@folder1.id} > ul#feeds-#{@folder1.id} > li > a[data-feed-id='#{@feed1.id}']", visible: false
      end

      it 'removes folder if it has no more feeds', js: true do
        find('#folder-management').click
        within '#folder-management-dropdown ul.dropdown-menu' do
          find("a[data-folder-id='#{@new_folder.id}']").click
        end

        sleep 1

        # Folder should be deleted from the database
        Folder.exists?(@folder1.id).should be_false

        # Folder should be removed from the sidebar
        within '#sidebar #folders-list' do
          page.should_not have_content @folder1.title
        end
        page.should_not have_css "#folders-list li[data-folder-id='#{@folder1.id}']"

        # Folder should be removed from the dropdown
        find('#folder-management').click
        within '#folder-management-dropdown ul.dropdown-menu' do
          page.should_not have_content @folder1.title
          page.should_not have_css "a[data-folder-id='#{@folder1.id}']"
        end
      end
      
      it 'does not remove folder if it has more feeds', js: true do
        # User has feeds @feed1, @feed2 in @folder1
        @user.feeds << @feed2
        @folder1.feeds << @feed2

        visit feeds_path
        read_feed @feed1.id

        find('#folder-management').click
        within '#folder-management-dropdown ul.dropdown-menu' do
          find("a[data-folder-id='#{@new_folder.id}']").click
        end

        sleep 1

        # Folder should not be deleted from the database
        Folder.exists?(@folder1.id).should be_true

        # Folder should not be removed from the sidebar
        within '#sidebar #folders-list' do
          page.should have_content @folder1.title
        end
        page.should have_css "#folders-list li[data-folder-id='#{@folder1.id}']"

        # Folder should not be removed from the dropdown
        find('#folder-management').click
        within '#folder-management-dropdown ul.dropdown-menu' do
          page.should have_content @folder1.title
          page.should have_css "a[data-folder-id='#{@folder1.id}']"
        end
      end

      it 'shows an alert if there is a problem adding a feed to a folder', js: true do
        User.any_instance.stub(:add_feed_to_folder).and_raise StandardError.new

        read_feed @feed2.id
        find('#folder-management').click
        sleep 1
        within '#folder-management-dropdown ul.dropdown-menu' do
          find("a[data-folder-id='#{@folder1.id}']").click
        end

        # A "problem managing folders" alert should be shown
        page.should have_css 'div#problem-folder-management'
        page.should_not have_css 'div#problem-folder-management.hidden', visible: false

        # It should close automatically after 5 seconds
        sleep 5
        page.should have_css 'div#problem-folder-management.hidden', visible: false
      end
    end

    context 'remove feed from folder' do

      it 'removes a feed from a folder', js: true do
        find('#folder-management').click
        within '#folder-management-dropdown ul.dropdown-menu' do
          find('a[data-folder-id="none"]').click
        end

        # Feed should be under the "All subscriptions" folder, without a data-folder-id attribute (because it doesn't belong to a folder)
        page.should have_css "li#folder-all > ul#feeds-all > li > a[data-feed-id='#{@feed1.id}'][data-folder-id='none']", visible: false

        # Feed should have disappeared from @folder1
        page.should_not have_css "li#folder-#{@folder1.id} > ul#feeds-#{@folder1.id} > li > a[data-feed-id='#{@feed1.id}']", visible: false
      end

      it 'does not remove the folder if there are other feeds inside it', js: true do
        # Ensure @folder1 contains @feed1 and @feed2
        @folder1.feeds << @feed2

        visit feeds_path

        # Remove @feed1 from folders
        read_feed @feed1.id
        find('#folder-management').click
        within '#folder-management-dropdown ul.dropdown-menu' do
          find('a[data-folder-id="none"]').click
        end

        # Page should still have @folder1 with @feed2 under it
        page.should have_css "#sidebar #folder-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed2.id}']", visible: false
      end

      it 'removes a folder from the sidebar when it has no feeds under it', js: true do
        find('#folder-management').click
        within '#folder-management-dropdown ul.dropdown-menu' do
          find('a[data-folder-id="none"]').click
        end

        page.should_not have_css "#sidebar #folder-#{@folder1.id}"
      end

      it 'removes a folder from the dropdown when it has no feeds under it', js: true do
        find('#folder-management').click
        within '#folder-management-dropdown ul.dropdown-menu' do
          find('a[data-folder-id="none"]').click
        end

        page.should_not have_css "#folder-management-dropdown a[data-folder-id='#{@folder1.id}']", visible: false
      end

      it 'shows an alert when there is a problem removing a feed from a folder', js: true do
        User.any_instance.stub(:remove_feed_from_folder).and_raise StandardError.new

        find('#folder-management').click
        within '#folder-management-dropdown ul.dropdown-menu' do
          find('a[data-folder-id="none"]').click
        end

        # A "problem managing folders" alert should be shown
        page.should have_css 'div#problem-folder-management'
        page.should_not have_css 'div#problem-folder-management.hidden', visible: false

        # It should close automatically after 5 seconds
        sleep 5
        page.should have_css 'div#problem-folder-management.hidden', visible: false
      end
    end

    context 'add feed to new folder' do

      it 'shows a popup to enter the folder name', js: true do
        find('#folder-management').click
        within '#folder-management-dropdown ul.dropdown-menu' do
          find('a[data-folder-id="new"]').click
        end

        page.should have_css '#new-folder-popup'
      end

      it 'adds a feed to a new folder', js: true do
        find('#folder-management').click
        within '#folder-management-dropdown ul.dropdown-menu' do
          find('a[data-folder-id="new"]').click
        end

        sleep 1
        title = 'New folder'
        within '#new-folder-popup' do
          fill_in 'Title', with: title
          find('#new-folder-submit').click
        end
        sleep 1

        # data-folder-id attribute should indicate that @feed1 is in the new folder
        new_folder = Folder.where(user_id: @user.id, title: title).first
        page.should have_css "#folder-#{new_folder.id} a[data-sidebar-feed][data-feed-id='#{@feed1.id}'][data-folder-id='#{new_folder.id}']"
      end

      it 'removes old folder if it has no more feeds', js: true do
        find('#folder-management').click
        within '#folder-management-dropdown ul.dropdown-menu' do
          find('a[data-folder-id="new"]').click
        end

        sleep 1
        title = 'New folder'
        within '#new-folder-popup' do
          fill_in 'Title', with: title
          find('#new-folder-submit').click
        end
        sleep 1

        # Folder should be deleted from the database
        Folder.where(id: @folder1.id).should be_blank

        # Folder should be removed from the sidebar
        within '#sidebar #folders-list' do
          page.should_not have_content @folder1.title
        end
        page.should_not have_css "#folders-list li[data-folder-id='#{@folder1.id}']"

        # Folder should be removed from the dropdown
        find('#folder-management').click
        within '#folder-management-dropdown ul.dropdown-menu' do
          page.should_not have_content @folder1.title
          page.should_not have_css "a[data-folder-id='#{@folder1.id}']"
        end
      end

      it 'does not remove old folder if it has more feeds', js: true do
        # @folder1 contains @feed1, @feed2
        @user.feeds << @feed2
        @folder1.feeds << @feed2
        visit feeds_path
        read_feed @feed1.id

        find('#folder-management').click
        within '#folder-management-dropdown ul.dropdown-menu' do
          find('a[data-folder-id="new"]').click
        end

        sleep 1
        title = 'New folder'
        within '#new-folder-popup' do
          fill_in 'Title', with: title
          find('#new-folder-submit').click
        end
        sleep 1

        # Folder should not be deleted from the database
        Folder.where(id: @folder1.id).should be_present

        # Folder should not be removed from the sidebar
        within '#sidebar #folders-list' do
          page.should have_content @folder1.title
        end
        page.should have_css "#folders-list li[data-folder-id='#{@folder1.id}']"

        # Folder should not be removed from the dropdown
        find('#folder-management').click
        within '#folder-management-dropdown ul.dropdown-menu' do
          page.should have_content @folder1.title
          page.should have_css "a[data-folder-id='#{@folder1.id}']"
        end
      end

      it 'removes feed from its old folder when adding it to a new one', js: true do
        # @folder1 contains @feed1, @feed2
        @user.feeds << @feed2
        @folder1.feeds << @feed2
        visit feeds_path
        read_feed @feed1.id

        # @feed1 can be found under @folder1 in the sidebar
        within "#sidebar #folders-list li[data-folder-id='#{@folder1.id}']" do
          page.should have_css "a[data-sidebar-feed][data-feed-id='#{@feed1.id}']", visible: false
        end

        find('#folder-management').click
        within '#folder-management-dropdown ul.dropdown-menu' do
          find('a[data-folder-id="new"]').click
        end

        sleep 1
        title = 'New folder'
        within '#new-folder-popup' do
          fill_in 'Title', with: title
          find('#new-folder-submit').click
        end
        sleep 1

        # @feed1 is no longer under @folder1
        within "#sidebar #folders-list li[data-folder-id='#{@folder1.id}']" do
          page.should_not have_css "a[data-sidebar-feed][data-feed-id='#{@feed1.id}']", visible: false
        end
      end

      it 'adds new folder to the sidebar', js: true do
        find('#folder-management').click
        within '#folder-management-dropdown ul.dropdown-menu' do
          find('a[data-folder-id="new"]').click
        end

        sleep 1
        title = 'New folder'
        within '#new-folder-popup' do
          fill_in 'Title', with: title
          find('#new-folder-submit').click
        end
        sleep 1

        new_folder = Folder.where(user_id: @user.id, title: title).first
        within '#sidebar #folders-list' do
          # new folder should be in the sidebar
          page.should have_content title
          page.should have_css "li#folder-#{new_folder.id}"
          # @feed1 should be under the new folder
          page.should have_css "li#folder-#{new_folder.id} a[data-feed-id='#{@feed1.id}'][data-folder-id='#{new_folder.id}']"
        end
      end

      it 'adds new folder to the dropdown', js: true do
        find('#folder-management').click
        within '#folder-management-dropdown ul.dropdown-menu' do
          find('a[data-folder-id="new"]').click
        end

        sleep 1
        title = 'New folder'
        within '#new-folder-popup' do
          fill_in 'Title', with: title
          find('#new-folder-submit').click
        end
        sleep 1

        new_folder = Folder.where(user_id: @user.id, title: title).first
        # Click on Folder button to open the dropdown
        find('#folder-management').click
        within '#folder-management-dropdown ul.dropdown-menu' do
          page.should have_content title
          # New folder should be in the dropdown, with a tick to indicate @feed1 is in the folder
          page.should have_css "a[data-feed-id='#{@feed1.id}'][data-folder-id='#{new_folder.id}'] i.icon-ok"
        end
      end

      it 'allows clicking on the dynamically added folder in the dropdown to move another feed into it', js: true do
        find('#folder-management').click
        within '#folder-management-dropdown ul.dropdown-menu' do
          find('a[data-folder-id="new"]').click
        end

        sleep 1
        title = 'New folder'
        within '#new-folder-popup' do
          fill_in 'Title', with: title
          find('#new-folder-submit').click
        end
        sleep 1

        new_folder = Folder.where(user_id: @user.id, title: title).first
        # data-folder-id attribute should indicate that @feed1 is in the new folder
        page.should have_css "#folder-#{new_folder.id} a[data-sidebar-feed][data-feed-id='#{@feed1.id}'][data-folder-id='#{new_folder.id}']"
        # @feed2 is still in no folder
        page.should have_css "#folder-all a[data-sidebar-feed][data-feed-id='#{@feed2.id}'][data-folder-id='none']"

        # Without reloading the page, move @feed2 to the new folder
        read_feed @feed2.id
        find('#folder-management').click
        within '#folder-management-dropdown ul.dropdown-menu' do
          find("a[data-folder-id='#{new_folder.id}']").click
        end

        # feed2 should have moved to the new folder
        page.should have_css "#folder-#{new_folder.id} a[data-sidebar-feed][data-feed-id='#{@feed2.id}'][data-folder-id='#{new_folder.id}']"
      end

      it 'shows an alert if there is a problem adding the feed to the new folder', js: true do
        User.any_instance.stub(:add_feed_to_new_folder).and_raise StandardError.new

        find('#folder-management').click
        within '#folder-management-dropdown ul.dropdown-menu' do
          find('a[data-folder-id="new"]').click
        end

        sleep 1
        title = 'New folder'
        within '#new-folder-popup' do
          fill_in 'Title', with: title
          find('#new-folder-submit').click
        end
        sleep 1

        page.should have_css '#problem-new-folder'

        # A "problem creating folder" alert should be shown
        page.should have_css 'div#problem-new-folder'
        page.should_not have_css 'div#problem-new-folder.hidden', visible: false

        # It should close automatically after 5 seconds
        sleep 5
        page.should have_css 'div#problem-new-folder.hidden', visible: false
      end

      it 'shows an alert if the user already has a folder with the same title', js: true do
        find('#folder-management').click
        within '#folder-management-dropdown ul.dropdown-menu' do
          find('a[data-folder-id="new"]').click
        end

        sleep 1
        within '#new-folder-popup' do
          fill_in 'Title', with: @folder1.title
          find('#new-folder-submit').click
        end
        sleep 1

        # A "problem creating folder" alert should be shown
        page.should have_css 'div#folder-already-exists'
        page.should_not have_css 'div#folder-already-exists.hidden', visible: false

        # It should close automatically after 5 seconds
        sleep 5
        page.should have_css 'div#folder-already-exists.hidden', visible: false
      end

      it 'does not show an alert if another user already has a folder with the same title', js: true do
        user2 = FactoryGirl.create :user
        folder = FactoryGirl.build :folder, user_id: user2.id
        user2.folders << folder

        find('#folder-management').click
        within '#folder-management-dropdown ul.dropdown-menu' do
          find('a[data-folder-id="new"]').click
        end

        sleep 1
        within '#new-folder-popup' do
          fill_in 'Title', with: folder.title
          find('#new-folder-submit').click
        end
        sleep 1

        # No alert should be shown
        page.should have_css 'div#folder-already-exists.hidden', visible: false
      end
    end

  end

end