require 'spec_helper'

describe OpmlExportJobState do

  before :each do
    @user = FactoryGirl.create :user
  end

  context 'validations' do

    it 'always belongs to a user' do
      opml_export_job_state = FactoryGirl.build :opml_export_job_state, user_id: nil
      opml_export_job_state.should_not be_valid
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
