require 'spec_helper'

describe ImportSubscriptionsJob do

  before :each do
    @user = FactoryGirl.create :user
    @data_import = FactoryGirl.build :data_import, user_id: @user.id, status: DataImport::RUNNING,
                                     total_feeds: 0, processed_feeds: 0
    @user.data_import = @data_import
    @filename = File.join File.dirname(__FILE__), '..', 'attachments', '1371324422.opml'
  end

  it 'updates the data import total number of feeds' do
    ImportSubscriptionsJob.perform @filename, @user.id
    @user.reload
    @user.data_import.total_feeds.should eq 4
  end

  it 'sets data import status to ERROR if the file does not exist'

  it 'sets data import status to ERROR if the file is not valid XML'

  it 'sets data import status to ERROR if the file is not valid OPML'

  it 'does nothing if the user does not exist'

  it 'subscribes user to already existing feeds'

  it 'updates data import number of processed feeds when subscribing user to existing feeds'

  it 'updates data import number of processed feeds when finding duplicated feeds'

  it 'creates new feeds and subscribes user to them'

  it 'enqueues job to fetch new feeds'

  it 'creates folder structure'

  it 'reuses folders already created by the user'

  it 'does not update data import number of processed feeds when subscribing user to new feeds'

  it 'sets data import status to SUCCESS if all feeds already existed'

  it 'leaves data import status as RUNNING if there were new feeds'

  it 'creates a data_import for the user if one does not exist'

end