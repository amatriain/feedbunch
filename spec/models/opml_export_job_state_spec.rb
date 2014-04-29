require 'spec_helper'

describe OpmlExportJobState do

  before :each do
    @user = FactoryGirl.create :user
    @filename = 'some_filename.opml'
  end

  context 'validations' do

    it 'always belongs to a user' do
      opml_export_job_state = FactoryGirl.build :opml_export_job_state, user_id: nil
      opml_export_job_state.should_not be_valid
    end

    it 'has filename if it has state SUCCESS' do
      opml_export_job_state = FactoryGirl.build :opml_export_job_state, user_id: @user.id,
                                                state: OpmlExportJobState::SUCCESS,
                                                filename: nil
      opml_export_job_state.should_not be_valid

      opml_export_job_state = FactoryGirl.build :opml_export_job_state, user_id: @user.id,
                                                state: OpmlExportJobState::SUCCESS,
                                                filename: @filename
      opml_export_job_state.should be_valid
    end

    it 'does not have a filename if it has state NONE' do
      opml_export_job_state = FactoryGirl.build :opml_export_job_state, user_id: @user.id,
                                                state: OpmlExportJobState::NONE,
                                                filename: @filename
      opml_export_job_state.should_not be_valid

      opml_export_job_state = FactoryGirl.build :opml_export_job_state, user_id: @user.id,
                                                state: OpmlExportJobState::NONE,
                                                filename: nil
      opml_export_job_state.should be_valid
    end

    it 'does not have a filename if it has state RUNNING' do
      opml_export_job_state = FactoryGirl.build :opml_export_job_state, user_id: @user.id,
                                                state: OpmlExportJobState::RUNNING,
                                                filename: @filename
      opml_export_job_state.should_not be_valid

      opml_export_job_state = FactoryGirl.build :opml_export_job_state, user_id: @user.id,
                                                state: OpmlExportJobState::RUNNING,
                                                filename: nil
      opml_export_job_state.should be_valid
    end

    it 'does not have a filename if it has state ERROR' do
      opml_export_job_state = FactoryGirl.build :opml_export_job_state, user_id: @user.id,
                                                state: OpmlExportJobState::ERROR,
                                                filename: @filename
      opml_export_job_state.should_not be_valid

      opml_export_job_state = FactoryGirl.build :opml_export_job_state, user_id: @user.id,
                                                state: OpmlExportJobState::ERROR,
                                                filename: nil
      opml_export_job_state.should be_valid
    end
  end

  context 'default values' do

    it 'defaults to state NONE when created' do
      @user.create_opml_export_job_state

      @user.opml_export_job_state.state.should eq OpmlExportJobState::NONE
    end

    it 'defaults show_alert to true' do
      opml_export_job_state = FactoryGirl.build :opml_export_job_state, show_alert: nil
      opml_export_job_state.save!
      opml_export_job_state.show_alert.should be_true
    end

  end

end
