require 'spec_helper'

describe 'import subscriptions' do
  before :each do
    @user = FactoryGirl.create :user

    login_user_for_feature @user
    visit feeds_path
    find('#start-page').click
  end

  it 'shows file upload popup', js: true do
    find('a[data-import-subscriptions]').click
    page.should have_css '#import-subscriptions-popup', visible: true
  end

  context 'user uploads file' do

    before :each do
      data_file = File.join File.dirname(__FILE__), '..', 'attachments', 'feedbunch@gmail.com-takeout.zip'
      find('a[data-import-subscriptions]').click
      attach_file 'import_subscriptions_file', data_file
      find('#import-subscriptions-submit').click
      sleep 1
    end

    it 'redirects to start page', js: true do
      current_path.should eq feeds_path
      page.should have_css '#start-info'
    end

    it 'shows error message', js: true do
      data_import = @user.data_import
      data_import.status = DataImport::ERROR
      data_import.save!

      visit feeds_path
      sleep 1

      page.should have_content 'There\'s been an error importing your subscriptions'
    end

    it 'shows success message', js: true do
      data_import = @user.data_import
      data_import.status = DataImport::SUCCESS
      data_import.save!

      visit feeds_path
      sleep 1

      page.should have_content 'Your subscriptions have been successfully imported into Feedbunch'
    end

    it 'shows import process progress', js: true do
      page.should have_content 'Your subscriptions are being imported into Feedbunch'
    end
  end
end