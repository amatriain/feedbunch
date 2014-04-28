require 'spec_helper'

describe OpmlImportJobState do

  before :each do
    @user = FactoryGirl.create :user
  end

  context 'validations' do

    it 'always belongs to a user' do
      data_import = FactoryGirl.build :opml_import_job_state, user_id: nil
      data_import.should_not be_valid
    end
  end

  context 'default values' do

    it 'defaults to state NONE when created' do
      @user.create_data_import

      @user.data_import.state.should eq OpmlImportJobState::NONE
    end

    it 'defaults to zero total_feeds' do
      data_import = FactoryGirl.create :opml_import_job_state, total_feeds: nil
      data_import.total_feeds.should eq 0
    end

    it 'defaults to zero processed_feeds' do
      data_import = FactoryGirl.create :opml_import_job_state, processed_feeds: nil
      data_import.processed_feeds.should eq 0
    end

    it 'defaults show_alert to true' do
      data_import = FactoryGirl.build :opml_import_job_state, show_alert: nil
      data_import.save!
      data_import.show_alert.should be_true
    end

  end

end
