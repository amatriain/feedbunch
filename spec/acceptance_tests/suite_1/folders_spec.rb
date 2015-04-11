require 'rails_helper'

describe 'folders and feeds', type: :feature do

  before :each do
    @user = FactoryGirl.create :user

    @folder1 = FactoryGirl.build :folder, user_id: @user.id
    @folder2 = FactoryGirl.build :folder, user_id: @user.id
    @user.folders << @folder1 << @folder2

    # Folder which exists but is not owned by @user
    @folder3 = FactoryGirl.create :folder

    @feed1 = FactoryGirl.create :feed
    @feed2 = FactoryGirl.create :feed

    @entry1_1 = FactoryGirl.build :entry, feed_id: @feed1.id
    @entry1_2 = FactoryGirl.build :entry, feed_id: @feed1.id
    @entry2_1 = FactoryGirl.build :entry, feed_id: @feed2.id
    @entry2_2 = FactoryGirl.build :entry, feed_id: @feed2.id
    @feed1.entries << @entry1_1 << @entry1_2
    @feed2.entries << @entry2_1 << @entry2_2

    @user.subscribe @feed1.fetch_url
    @user.subscribe @feed2.fetch_url
    @folder1.feeds << @feed1
  end

  it 'shows an alert if it cannot load folders', js: true do
    skip
    allow_any_instance_of(User).to receive(:folders).and_raise StandardError.new
    login_user_for_feature @user
    should_show_alert 'problem-loading-folders'
  end

  context 'show folders' do

    before :each do
      login_user_for_feature @user
    end

    it 'shows only folders that belong to the user', js: true do
      expect(page).to have_content @folder1.title
      expect(page).to have_no_content @folder3.title
    end

    it 'shows a list with feeds which are not in any folder', js: true do
      # @feed1 is in a folder and should not be in the list. Only @feed2 should be there.
      expect(page).to have_css "#sidebar #folders-list #folder-none a[data-sidebar-feed][data-feed-id='#{@feed2.id}']"
      expect(page).to have_no_css "#sidebar #folders-list #folder-none a[data-sidebar-feed][data-feed-id='#{@feed1.id}']"
    end

    it 'shows folders containing their respective feeds', js: true do
      within '#sidebar' do
        expect(page).to have_content @folder1.title

        open_folder @folder1

        within "#folders-list #folder-#{@folder1.id}" do
          expect(page).to have_css "a#open-folder-#{@folder1.id}"

          # Folder should be open (class "in" present)
          expect(page).to have_css "#feeds-#{@folder1.id}", visible: true

          # Should have inside only those feeds associated to the folder
          within "#feeds-#{@folder1.id}" do
            expect(page).to have_css "a[data-sidebar-feed][data-feed-id='#{@feed1.id}']"
            expect(page).to have_no_css "a[data-sidebar-feed][data-feed-id='#{@feed2.id}']"
          end
        end
      end
    end

    it 'only shows folders with unread entries by default', js: true do
      # @user is subscribed to feed3, without unread entries, which is the only feed in folder3
      folder3 = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder3
      feed3 = FactoryGirl.create :feed
      @user.subscribe feed3.fetch_url
      folder3.feeds << feed3

      visit read_path
      # folder3 should be hidden
      expect(page).to have_no_content folder3.title
    end

    it 'shows folders without unread entries if a feed in the folder has a subscribe job state alert', js: true do
      # feed3 has a subscribe job state alert in the start page
      # feed3 is the only feed in folder3, and it has no unread entries
      folder3 = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder3
      feed3 = FactoryGirl.create :feed
      @user.subscribe feed3.fetch_url
      folder3.feeds << feed3
      subscribe_job_state = FactoryGirl.build SubscribeJobState, state: SubscribeJobState::SUCCESS,
                                              feed_id: feed3.id, user_id: @user.id
      @user.subscribe_job_states << subscribe_job_state

      visit read_path

      #folder3 should be visible
      expect(page).to have_content folder3.title
    end

    it 'shows folders without unread entries if a feed in the folder has a refresh job state alert', js: true do
      # feed3 has a refresh job state alert in the start page
      # feed3 is the only feed in folder3, and it has no unread entries
      folder3 = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder3
      feed3 = FactoryGirl.create :feed
      @user.subscribe feed3.fetch_url
      folder3.feeds << feed3
      refresh_feed_job_state = FactoryGirl.build RefreshFeedJobState, state: SubscribeJobState::SUCCESS,
                                                 feed_id: feed3.id, user_id: @user.id
      @user.refresh_feed_job_states << refresh_feed_job_state

      visit read_path

      #folder3 should be visible
      expect(page).to have_content folder3.title
    end

    it 'shows folders without unread entries and hides them again when clicking on the button', js: true do
      # @user is subscribed to feed3, without unread entries, which is the only feed in folder3
      folder3 = FactoryGirl.build :folder, user_id: @user.id
      @user.folders << folder3
      feed3 = FactoryGirl.create :feed
      @user.subscribe feed3.fetch_url
      folder3.feeds << feed3

      visit read_path
      show_read
      # folder3 should appear
      expect(page).to have_content folder3.title

      hide_read
      # folder3 should disappear
      expect(page).to have_no_content folder3.title
    end
  end

  context 'folder management' do

    before :each do
      login_user_for_feature @user
      read_feed @feed1, @user
    end

    it 'hides folder management button until a feed is selected', js: true do
      visit read_path
      expect(page).to have_no_css '#folder-management', visible: true
    end

    it 'shows folder management button when a feed is selected', js: true do
      expect(page).to have_no_css '#folder-management.hidden', visible: false
      expect(page).to have_no_css '#folder-management.disabled', visible: false
      expect(page).to have_css '#folder-management'
    end

    it 'hides folder management button when reading a whole folder', js: true do
      # @feed1 and feed3 are in @folder1
      feed3 = FactoryGirl.create :feed
      entry3 = FactoryGirl.build :entry, feed_id: feed3.id
      feed3.entries << entry3
      @user.subscribe feed3.fetch_url
      @folder1.feeds << feed3
      visit read_path

      read_folder @folder1
      expect(page).to have_no_css '#folder-management', visible: true
      expect(page).to have_no_css '#folder-management', visible: true
    end

    it 'drops down a list of all user folders', js: true do
      open_folder_dropdown
      within '#folder-management-dropdown ul.dropdown-menu' do
        expect(page).to have_content @folder1.title
      end
    end

    it 'has No Folder and New Folder links in the dropdown', js: true do
      open_folder_dropdown
      within '#folder-management-dropdown' do
        expect(page).to have_css 'a[data-folder-id="none"]'
        expect(page).to have_css 'a[data-folder-id="new"]'
      end
    end

    it 'shows a tick besides No Folder when the feed is not in a folder', js: true do
      read_feed @feed2, @user
      open_folder_dropdown
      within '#folder-management-dropdown' do
        # tick should be only besides No Folder
        expect(page).to have_css 'a[data-folder-id="none"] > i.fa.fa-check'
        expect(page).to have_no_css "li[data-folder-id='#{@folder1.id}'] a > i.fa.fa-check"
      end
    end

    it 'shows a tick besides the folder name when the feed is in a folder', js: true do
      open_folder_dropdown
      within '#folder-management-dropdown' do
        # tick should be only besides @folder1
        expect(page).to have_no_css 'li[data-folder-id="none"] a > i.fa.fa-check'
        expect(page).to have_css "a[data-folder-id='#{@folder1.id}'] > i.fa.fa-check"
      end
    end

    context 'add feed to existing folder' do
      
      it 'adds a feed to an existing folder', js: true do
        move_feed_to_folder @feed2, @folder1, @user

        should_show_alert 'move-to-folder-success'
        # the feed should be in the sidebar under the @folder1 folder
        expect(page).to have_css "#folder-#{@folder1.id} #feeds-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed2.id}'][data-folder-id='#{@folder1.id}']", visible: false
      end

      it 'removes feed from its old folder when adding it to a different one', js: true do
        # User has feeds @feed1, @feed2 in @folder1
        @folder1.feeds << @feed2

        visit read_path
        # @feed1 should be under @folder1
        expect(page).to have_css "#folder-#{@folder1.id} #feeds-#{@folder1.id} a[data-feed-id='#{@feed1.id}'][data-folder-id='#{@folder1.id}']", visible: false

        move_feed_to_folder @feed1, @folder2, @user

        # the feed should be in the sidebar under the @folder2 folder
        expect(page).to have_css "#folder-#{@folder2.id} #feeds-#{@folder2.id} a[data-feed-id='#{@feed1.id}'][data-folder-id='#{@folder2.id}']", visible: false

        # the feed should have disappeared from @folder1
        expect(page).to have_no_css "#folder-#{@folder1.id} #feeds-#{@folder1.id} a[data-feed-id='#{@feed1.id}']", visible: false
      end

      it 'removes folder if it has no more feeds', js: true do
        move_feed_to_folder @feed1, @folder2, @user

        # Folder should be removed from the sidebar
        within '#sidebar #folders-list' do
          expect(page).to have_no_content @folder1.title
        end
        expect(page).to have_no_css "#folders-list li[data-folder-id='#{@folder1.id}']"

        # Folder should be removed from the dropdown
        open_folder_dropdown
        within '#folder-management-dropdown ul.dropdown-menu' do
          expect(page).to have_no_content @folder1.title
          expect(page).to have_no_css "a[data-folder-id='#{@folder1.id}']"
        end
      end

      # Regression test for bug #165
      it 'does not change feed/folder if user tries to move a feed to the same folder it already is at', js: true do
        # @feed1 is already in @folder1, user clicks on @folder1 in the dropdown
        move_feed_to_folder @feed1, @folder1, @user

        # Folder should not be removed from the sidebar
        within '#sidebar #folders-list' do
          expect(page).to have_content @folder1.title
        end
        expect(page).to have_css "#folders-list [data-folder-id='#{@folder1.id}']"

        # Folder should not be removed from the dropdown
        open_folder_dropdown
        within '#folder-management-dropdown ul.dropdown-menu' do
          expect(page).to have_content @folder1.title
          expect(page).to have_css "a[data-folder-id='#{@folder1.id}']"
        end

        # @feed1 should be in the sidebar under the @folder1 folder
        expect(page).to have_css "#folder-#{@folder1.id} #feeds-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed1.id}'][data-folder-id='#{@folder1.id}']", visible: false

        # No alert should be shown
        should_hide_alert 'problem-folder-management'
      end
      
      it 'does not remove folder if it has more feeds', js: true do
        # User has feeds @feed1, @feed2 in @folder1
        @folder1.feeds << @feed2

        visit read_path
        expect(page).to have_css "#folder-#{@folder1.id} #feeds-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed2.id}'][data-folder-id='#{@folder1.id}']", visible: false

        move_feed_to_folder @feed1, @folder2, @user

        # Folder should not be removed from the sidebar
        within '#sidebar #folders-list' do
          expect(page).to have_content @folder1.title
        end
        expect(page).to have_css "#folders-list [data-folder-id='#{@folder1.id}']"

        # Folder should not be removed from the dropdown
        open_folder_dropdown
        within '#folder-management-dropdown ul.dropdown-menu' do
          expect(page).to have_content @folder1.title
          expect(page).to have_css "a[data-folder-id='#{@folder1.id}']"
        end
      end

      it 'shows an alert if there is a problem adding a feed to a folder', js: true do
        allow_any_instance_of(User).to receive(:move_feed_to_folder).and_raise StandardError.new

        read_feed @feed2, @user
        open_folder_dropdown
        within '#folder-management-dropdown ul.dropdown-menu' do
          find("a[data-folder-id='#{@folder1.id}']").click
        end

        should_show_alert 'problem-folder-management'
      end
    end

    context 'remove feed from folder' do

      it 'removes a feed from a folder', js: true do
        remove_feed_from_folder @feed1, @user

        should_show_alert 'remove-from-folder-success'
        # Feed should be under the "All subscriptions" folder, without a data-folder-id attribute (because it doesn't belong to a folder)
        expect(page).to have_css "#sidebar #folder-none a[data-feed-id='#{@feed1.id}'][data-folder-id='none']", visible: false

        # Feed should have disappeared from @folder1
        expect(page).to have_no_css "#folder-#{@folder1.id} #feeds-#{@folder1.id} a[data-feed-id='#{@feed1.id}']", visible: false
      end

      it 'does not remove the folder if there are other feeds inside it', js: true do
        # Ensure @folder1 contains @feed1 and @feed2
        @folder1.feeds << @feed2

        visit read_path
        remove_feed_from_folder @feed1, @user

        # Page should still have @folder1 with @feed2 under it
        expect(page).to have_css "#sidebar #folder-#{@folder1.id} a[data-sidebar-feed][data-feed-id='#{@feed2.id}']", visible: false
      end

      it 'removes a folder from the sidebar when it has no feeds under it', js: true do
        remove_feed_from_folder @feed1, @user

        expect(page).to have_no_css "#sidebar #folder-#{@folder1.id}"
      end

      it 'removes a folder from the dropdown when it has no feeds under it', js: true do
        remove_feed_from_folder @feed1, @user

        expect(page).to have_no_css "#folder-management-dropdown a[data-folder-id='#{@folder1.id}']", visible: false
      end

      it 'shows an alert when there is a problem removing a feed from a folder', js: true do
        allow_any_instance_of(User).to receive(:move_feed_to_folder).and_raise StandardError.new

        read_feed @feed1, @user
        open_folder_dropdown
        within '#folder-management-dropdown ul.dropdown-menu' do
          find('a[data-folder-id="none"]').click
        end

        should_show_alert 'problem-folder-management'
      end
    end

    context 'add feed to new folder' do

      it 'shows a popup to enter the folder name', js: true do
        open_folder_dropdown
        within '#folder-management-dropdown ul.dropdown-menu' do
          find('a[data-folder-id="new"]').click
        end

        expect(page).to have_css '#new-folder-popup'
      end

      it 'adds a feed to a new folder', js: true do
        title = 'New folder'
        move_feed_to_new_folder @feed1, title, @user

        should_show_alert 'move-to-new-folder-success'
        # data-folder-id attribute should indicate that @feed1 is in the new folder
        new_folder = Folder.find_by user_id: @user.id, title: title
        open_folder new_folder
        expect(page).to have_css "#folder-#{new_folder.id} a[data-sidebar-feed][data-feed-id='#{@feed1.id}'][data-folder-id='#{new_folder.id}']"
      end

      it 'removes old folder if it has no more feeds', js: true do
        title = 'New folder'
        move_feed_to_new_folder @feed1, title, @user

        # Folder should be deleted from the database
        expect(Folder.where(id: @folder1.id)).to be_blank

        # Folder should be removed from the sidebar
        within '#sidebar #folders-list' do
          expect(page).to have_no_content @folder1.title
        end
        expect(page).to have_no_css "#folders-list li[data-folder-id='#{@folder1.id}']"

        # Folder should be removed from the dropdown
        open_folder_dropdown
        within '#folder-management-dropdown ul.dropdown-menu' do
          expect(page).to have_no_content @folder1.title
          expect(page).to have_no_css "a[data-folder-id='#{@folder1.id}']"
        end
      end

      it 'does not remove old folder if it has more feeds', js: true do
        # @folder1 contains @feed1, @feed2
        @folder1.feeds << @feed2
        visit read_path
        read_feed @feed1, @user

        title = 'New folder'
        move_feed_to_new_folder @feed1, title, @user

        # Folder should not be deleted from the database
        expect(Folder.where(id: @folder1.id)).to be_present

        # Folder should not be removed from the sidebar
        within '#sidebar #folders-list' do
          expect(page).to have_content @folder1.title
        end
        expect(page).to have_css "#folders-list [data-folder-id='#{@folder1.id}']"

        # Folder should not be removed from the dropdown
        open_folder_dropdown
        within '#folder-management-dropdown ul.dropdown-menu' do
          expect(page).to have_content @folder1.title
          expect(page).to have_css "a[data-folder-id='#{@folder1.id}']"
        end
      end

      it 'removes feed from its old folder when adding it to a new one', js: true do
        # @folder1 contains @feed1, @feed2
        @folder1.feeds << @feed2
        visit read_path
        read_feed @feed1, @user

        # @feed1 can be found under @folder1 in the sidebar
        within "#sidebar #folders-list #folder-#{@folder1.id}" do
          expect(page).to have_css "a[data-sidebar-feed][data-feed-id='#{@feed1.id}']", visible: false
        end

        title = 'New folder'
        move_feed_to_new_folder @feed1, title, @user

        # @feed1 is no longer under @folder1
        within "#sidebar #folders-list #folder-#{@folder1.id}" do
          expect(page).to have_no_css "a[data-sidebar-feed][data-feed-id='#{@feed1.id}']", visible: false
        end
      end

      it 'adds new folder to the sidebar', js: true do
        title = 'New folder'
        move_feed_to_new_folder @feed1, title, @user

        new_folder = Folder.find_by user_id: @user.id, title: title
        open_folder new_folder
        within '#sidebar #folders-list' do
          # new folder should be in the sidebar
          expect(page).to have_content title
          expect(page).to have_css "#folder-#{new_folder.id}"
          # @feed1 should be under the new folder
          expect(page).to have_css "#folder-#{new_folder.id} a[data-feed-id='#{@feed1.id}'][data-folder-id='#{new_folder.id}']"
        end
      end

      it 'adds new folder to the dropdown', js: true do
        title = 'New folder'
        move_feed_to_new_folder @feed1, title, @user

        new_folder = Folder.find_by user_id: @user.id, title: title
        # Click on Folder button to open the dropdown
        open_folder_dropdown
        within '#folder-management-dropdown ul.dropdown-menu' do
          expect(page).to have_content title
          # New folder should be in the dropdown, with a tick to indicate @feed1 is in the folder
          expect(page).to have_css "a[data-folder-id='#{new_folder.id}'] i.fa.fa-check"
        end
      end

      it 'allows clicking on the dynamically added folder in the dropdown to move another feed into it', js: true do
        title = 'New folder'
        move_feed_to_new_folder @feed1, title, @user

        new_folder = Folder.find_by user_id: @user.id, title: title
        # data-folder-id attribute should indicate that @feed1 is in the new folder
        open_folder new_folder
        expect(page).to have_css "#folder-#{new_folder.id} a[data-sidebar-feed][data-feed-id='#{@feed1.id}'][data-folder-id='#{new_folder.id}']"

        # Without reloading the page, move @feed2 to the new folder
        read_feed @feed2, @user
        open_folder_dropdown
        within '#folder-management-dropdown ul.dropdown-menu' do
          find("a[data-folder-id='#{new_folder.id}']").click
        end

        # feed2 should have moved to the new folder
        open_folder new_folder
        expect(page).to have_css "#folder-#{new_folder.id} a[data-sidebar-feed][data-feed-id='#{@feed2.id}'][data-folder-id='#{new_folder.id}']"
      end

      it 'shows an alert if there is a problem adding the feed to the new folder', js: true do
        allow_any_instance_of(User).to receive(:move_feed_to_folder).and_raise StandardError.new
        title = 'New folder'

        read_feed @feed1, @user
        open_folder_dropdown
        within '#folder-management-dropdown ul.dropdown-menu' do
          find('a[data-folder-id="new"]').click
        end
        expect(page).to have_css '#new-folder-popup'
        within '#new-folder-popup' do
          fill_in 'Title', with: title
          find('#new-folder-submit').click
        end

        expect(page).to have_css '#problem-new-folder'

        should_show_alert 'problem-new-folder'
      end

      it 'shows an alert if the user already has a folder with the same title', js: true do
        move_feed_to_new_folder @feed1, @folder1.title, @user

        should_show_alert 'folder-already-exists'
      end

      it 'does not show an alert if another user already has a folder with the same title', js: true do
        user2 = FactoryGirl.create :user
        folder = FactoryGirl.build :folder, user_id: user2.id
        user2.folders << folder

        should_hide_alert 'folder-already-exists'
      end
    end

  end

end