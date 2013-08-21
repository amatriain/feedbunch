require 'spec_helper'

describe ImportSubscriptionsJob do

  before :each do
    # Ensure files are not deleted, we will need them for running tests again!
    File.stub(:delete).and_return 1

    @user = FactoryGirl.create :user
    @data_import = FactoryGirl.build :data_import, user_id: @user.id, status: DataImport::RUNNING,
                                     total_feeds: 0, processed_feeds: 0
    @user.data_import = @data_import

    @filename = '1371324422.opml'
    @filepath = File.join __dir__, '..', 'attachments', @filename
    @file_contents = File.read @filepath

    Feedbunch::Application.config.uploads_manager.stub :read do |filename|
      if filename == @filename
        @file_contents
      else
        nil
      end
    end
    Feedbunch::Application.config.uploads_manager.stub :save
    Feedbunch::Application.config.uploads_manager.stub :delete

    @brakeman_feed = FactoryGirl.create :feed, title: 'Brakeman - Rails Security Scanner',
                                        fetch_url: 'http://brakemanscanner.org/atom.xml',
                                        url: 'http://brakemanscanner.org/'
    @xkcd_feed = FactoryGirl.create :feed, title: 'xkcd.com', fetch_url: 'http://xkcd.com/rss.xml',
                                    url: 'http://xkcd.com/'

    # Stub FeedClient.stub so that it does not actually fetch feeds, but returns them untouched
    FeedClient.stub :fetch do |feed, perform_autodiscovery|
      feed
    end
  end

  it 'updates the data import total number of feeds' do
    ImportSubscriptionsJob.perform @filename, @user.id
    @user.reload
    @user.data_import.total_feeds.should eq 4
  end

  it 'sets data import status to ERROR if the file does not exist' do
    ImportSubscriptionsJob.perform 'not.a.real.file', @user.id
    @user.reload
    @user.data_import.status.should eq DataImport::ERROR
  end

  it 'sets data import status to ERROR if the file is not well formed XML' do
    not_valid_xml_filename = File.join __dir__, '..', 'attachments', 'not-well-formed-xml.opml'
    file_contents = File.read not_valid_xml_filename
    Feedbunch::Application.config.uploads_manager.stub read: file_contents
    ImportSubscriptionsJob.perform not_valid_xml_filename, @user.id
    @user.reload
    @user.data_import.status.should eq DataImport::ERROR
  end

  it 'sets data import status to ERROR if the file is not valid OPML' do
    not_valid_opml_filename = File.join __dir__, '..', 'attachments', 'not-valid-opml.opml'
    file_contents = File.read not_valid_opml_filename
    Feedbunch::Application.config.uploads_manager.stub read: file_contents
    ImportSubscriptionsJob.perform not_valid_opml_filename, @user.id
    @user.reload
    @user.data_import.status.should eq DataImport::ERROR
  end

  it 'does nothing if the user does not exist' do
    Feedbunch::Application.config.uploads_manager.should_not_receive :read
    ImportSubscriptionsJob.perform @filename, 1234567890
  end

  it 'reads uploaded file' do
    Feedbunch::Application.config.uploads_manager.should_receive(:read).with @filename
    ImportSubscriptionsJob.perform @filename, @user.id
  end

  it 'subscribes user to already existing feeds' do
    @user.feeds.should_not include @brakeman_feed
    @user.feeds.should_not include @xkcd_feed
    ImportSubscriptionsJob.perform @filename, @user.id
    @user.reload
    @user.feeds.should include @brakeman_feed
    @user.feeds.should include @xkcd_feed
  end

  it 'updates data import number of processed feeds when subscribing user to existing feeds' do
    @user.data_import.processed_feeds.should eq 0
    ImportSubscriptionsJob.perform @filename, @user.id
    @user.reload
    @user.data_import.processed_feeds.should eq 4
  end

  it 'updates data import number of processed feeds when finding duplicated feeds' do
    filename = File.join __dir__, '..', 'attachments', '1371324422-with-duplicate-feed.opml'
    file_contents = File.read filename
    Feedbunch::Application.config.uploads_manager.stub read: file_contents
    ImportSubscriptionsJob.perform filename, @user.id
    @user.reload
    @user.data_import.total_feeds.should eq 5
    @user.data_import.processed_feeds.should eq 5
  end

  it 'ignores feeds without xmlUrl attribute' do
    filename = File.join __dir__, '..', 'attachments', '1371324422-with-feed-without-attributes.opml'
    file_contents = File.read filename
    Feedbunch::Application.config.uploads_manager.stub read: file_contents

    FeedClient.should_receive(:fetch) do |feed, perform_autodiscovery|
      feed.fetch_url.should eq 'https://www.archlinux.org/feeds/news/'
      perform_autodiscovery.should be_true
    end

    ImportSubscriptionsJob.perform filename, @user.id

    @user.reload
    @user.data_import.total_feeds.should eq 3
    @user.data_import.processed_feeds.should eq 3
    @user.data_import.status.should eq DataImport::SUCCESS
  end

  it 'creates new feeds and subscribes user to them' do
    url1 = 'http://www.galactanet.com/feed.xml'
    url2 = 'http://www.galactanet.com/feed.xml'

    Feed.exists?(fetch_url: url1).should be_false
    Feed.exists?(fetch_url: url2).should be_false

    ImportSubscriptionsJob.perform @filename, @user.id

    @user.reload
    @user.feeds.where(fetch_url: url1).should be_present
    @user.feeds.where(fetch_url: url2).should be_present
  end

  it 'fetches new feeds' do
    andy_feed_enqueued = false
    arch_feed_enqueued = false
    FeedClient.should_receive(:fetch).twice do |feed, perform_autodiscovery|
      andy_feed_enqueued = true if feed.fetch_url == 'http://www.galactanet.com/feed.xml'
      arch_feed_enqueued = true if feed.fetch_url == 'https://www.archlinux.org/feeds/news/'
    end

    ImportSubscriptionsJob.perform @filename, @user.id
    andy_feed_enqueued.should be_true
    arch_feed_enqueued.should be_true
  end

  it 'creates folder structure' do
    @user.folders.should be_blank
    ImportSubscriptionsJob.perform @filename, @user.id

    @user.reload
    @user.folders.count.should eq 2

    folder_linux = @user.folders.where(title: 'Linux').first
    folder_linux.should be_present
    folder_linux.feeds.count.should eq 1
    folder_linux.feeds.where(fetch_url: 'https://www.archlinux.org/feeds/news/').should be_present

    folder_webcomics = @user.folders.where(title: 'Webcomics').first
    folder_webcomics.should be_present
    folder_webcomics.feeds.count.should eq 1
    folder_webcomics.feeds.where(fetch_url: 'http://xkcd.com/rss.xml').should be_present
  end

  it 'reuses folders already created by the user' do
    folder_linux = FactoryGirl.build :folder, title: 'Linux', user_id: @user.id
    @user.folders << folder_linux
    ImportSubscriptionsJob.perform @filename, @user.id

    @user.reload
    @user.folders.count.should eq 2

    @user.folders.should include folder_linux
    folder_linux.feeds.count.should eq 1
    folder_linux.feeds.where(fetch_url: 'https://www.archlinux.org/feeds/news/').should be_present

    folder_webcomics = @user.folders.where(title: 'Webcomics').first
    folder_webcomics.should be_present
    folder_webcomics.feeds.count.should eq 1
    folder_webcomics.feeds.where(fetch_url: 'http://xkcd.com/rss.xml').should be_present
  end

  it 'sets data import status to SUCCESS if all feeds already existed' do
    andy_weir_feed = FactoryGirl.create :feed, title: "Andy Weir's Writing",
                                        fetch_url: 'http://www.galactanet.com/feed.xml',
                                        url: 'http://www.galactanet.com/writing.html'
    arch_feed = FactoryGirl.create :feed, title: 'Arch Linux: Recent news updates',
                                   fetch_url: 'https://www.archlinux.org/feeds/news/',
                                   url: 'https://www.archlinux.org/news/'
    ImportSubscriptionsJob.perform @filename, @user.id

    @user.reload
    @user.data_import.total_feeds.should eq 4
    @user.data_import.processed_feeds.should eq 4
    @user.data_import.status.should eq DataImport::SUCCESS
  end

  it 'leaves data import status as SUCCESS if there were new feeds' do
    ImportSubscriptionsJob.perform @filename, @user.id

    @user.reload
    @user.data_import.status.should eq DataImport::SUCCESS
  end

  it 'creates a data_import for the user if one does not exist' do
    @user.data_import.destroy
    ImportSubscriptionsJob.perform @filename, @user.id
    @user.reload
    @user.data_import.should be_present
  end

  it 'does nothing if the data_import for the user has status ERROR' do
    @user.data_import.status = DataImport::ERROR
    @user.data_import.save
    Feedbunch::Application.config.uploads_manager.should_not_receive :read
    ImportSubscriptionsJob.perform @filename, @user.id
  end

  it 'does nothing if the data_import for the user has status SUCCESS' do
    @user.data_import.status = DataImport::SUCCESS
    @user.data_import.save
    Feedbunch::Application.config.uploads_manager.should_not_receive :read
    ImportSubscriptionsJob.perform @filename, @user.id
  end

  it 'deletes file after finishing successfully' do
    Feedbunch::Application.config.uploads_manager.should_receive(:delete).with @filename
    ImportSubscriptionsJob.perform @filename, @user.id
  end

  it 'deletes file after finishing with an error' do
    Feedbunch::Application.config.uploads_manager.should_receive(:delete).with @filename
    ImportSubscriptionsJob.perform @filename, 1234567890
  end

end