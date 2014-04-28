require 'spec_helper'

describe User do
  before :each do
    @user = FactoryGirl.create :user
  end

  context 'export subscriptions' do

    it 'has a opml_export_job_state with state NONE as soon as the user is created' do
      @user.opml_export_job_state.should be_present
      @user.opml_export_job_state.state.should eq OpmlExportJobState::NONE
    end

    it 'creates a new opml_export_job_state with state RUNNING for the user' do
      @user.export_subscriptions
      @user.opml_export_job_state.should be_present
      @user.opml_export_job_state.state.should eq OpmlExportJobState::RUNNING
    end

    it 'sets opml_import_job_state state as ERROR if an error is raised' do
      Resque.stub(:enqueue).and_raise StandardError.new
      expect{@user.export_subscriptions}.to raise_error StandardError

      @user.opml_export_job_state.state.should eq OpmlExportJobState::ERROR
    end

  end

  context 'change alert visibility' do

    it 'hides alert' do
      @user.opml_export_job_state.show_alert.should be_true
      @user.set_opml_export_job_state_visible false
      @user.reload.opml_export_job_state.show_alert.should be_false
    end

    it 'shows alert' do
      @user.opml_export_job_state.update show_alert: false
      @user.set_opml_export_job_state_visible true
      @user.reload.opml_export_job_state.show_alert.should be_true
    end
  end


end
