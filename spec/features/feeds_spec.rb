require 'spec_helper'

describe 'feeds' do
  before :each do
    # Ensure no actual HTTP calls are made
    FeedClient.stub :fetch
    RestClient.stub :get
  end

  it 'redirects unauthenticated visitors to login page' do
    visit feeds_path
    current_path.should eq new_user_session_path
  end

  context 'subscribed feeds' do

    before :each do
      @user = FactoryGirl.create :user
      @feed1 = FactoryGirl.create :feed
      @feed2 = FactoryGirl.create :feed
      @user.feeds << @feed1

      login_user_for_feature @user
      visit feeds_path
    end

    it 'shows feeds the user is subscribed to' do
      page.should have_content @feed1.title
    end

    it 'does not show feeds the user is not subscribed to' do
      page.should_not have_content @feed2.title
    end
  end

  context 'folders' do

    before :each do
      @user = FactoryGirl.create :user

      @folder1 = FactoryGirl.build :folder, user_id: @user.id
      @folder2 = FactoryGirl.create :folder
      @user.folders << @folder1

      @feed1 = FactoryGirl.build :feed
      @feed2 = FactoryGirl.build :feed
      @user.feeds << @feed1 << @feed2
      @folder1.feeds << @feed1

      login_user_for_feature @user
      visit feeds_path
    end

    it 'shows folders that belong to the user' do
      page.should have_content @folder1.title
    end

    it 'does not show folders that do not belong to the user' do
      page.should_not have_content @folder2.title
    end

    it 'has an All Feeds folder with all feeds', js: true do
      within 'ul#sidebar' do
        page.should have_content 'All feeds'

        within 'li#folder-all' do
          page.should have_css "a[data-target='#feeds-all']"

          # "All feeds" folder should be closed (class "in" not present)
          page.should_not have_css 'ul#feeds-all.in'

          # Open "All feeds" folder (should acquire class "in")
          find("a[data-target='#feeds-all']").click
          page.should have_css 'ul#feeds-all.in'

          # Should have all the feeds inside
          within 'ul#feeds-all' do
            page.should have_css "li#feed-#{@feed1.id}"
            page.should have_css "li#feed-#{@feed2.id}"
          end
        end
      end
    end

    it 'has a link to read all subscriptions inside the All Feeds folder'

    it 'has folders containing their respective feeds', js: true do
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
            page.should have_css "li#feed-#{@feed1.id}"
            page.should_not have_css "li#feed-#{@feed2.id}"
          end
        end
      end
    end

    it 'has a link to read all feeds inside each folder'
  end
end