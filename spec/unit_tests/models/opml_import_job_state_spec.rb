require 'spec_helper'

describe OpmlImportJobState, type: :model do

  before :each do
    @user = FactoryGirl.create :user
  end

  context 'validations' do

    it 'always belongs to a user' do
      opml_import_job_state = FactoryGirl.build :opml_import_job_state, user_id: nil
      opml_import_job_state.should_not be_valid
    end
  end

  context 'default values' do

    it 'defaults to state NONE when created' do
      @user.create_opml_import_job_state

      @user.opml_import_job_state.state.should eq OpmlImportJobState::NONE
    end

    it 'defaults to zero total_feeds' do
      opml_import_job_state = FactoryGirl.create :opml_import_job_state, total_feeds: nil
      opml_import_job_state.total_feeds.should eq 0
    end

    it 'defaults to zero processed_feeds' do
      opml_import_job_state = FactoryGirl.create :opml_import_job_state, processed_feeds: nil
      opml_import_job_state.processed_feeds.should eq 0
    end

    it 'defaults show_alert to true' do
      opml_import_job_state = FactoryGirl.build :opml_import_job_state, show_alert: nil
      opml_import_job_state.save!
      opml_import_job_state.show_alert.should be_true
    end

  end

end
