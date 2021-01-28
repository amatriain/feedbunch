# frozen_string_literal: true

require 'rails_helper'

describe NotifyImportFinishedWorker do

  before :each do
    @user = FactoryBot.create :user
    @opml_import_job_state = FactoryBot.build :opml_import_job_state, user_id: @user.id, state: OpmlImportJobState::RUNNING,
                                     total_feeds: 4, processed_feeds: 4
    @user.opml_import_job_state = @opml_import_job_state

    # Remove emails still in the mail queue
    ActionMailer::Base.deliveries.clear
  end

  context 'validations' do

    it 'does nothing if the job state does not exist' do
      NotifyImportFinishedWorker.new.perform 1234567890
      mail_should_not_be_sent
    end

    it 'does nothing if the opml_import_job_state has state NONE' do
      @opml_import_job_state.update state: OpmlImportJobState::NONE
      NotifyImportFinishedWorker.new.perform @opml_import_job_state.id
      mail_should_not_be_sent
      expect(@opml_import_job_state.reload.state).to eq OpmlImportJobState::NONE
    end

    it 'does nothing if the opml_import_job_state has state ERROR' do
      @opml_import_job_state.update state: OpmlImportJobState::ERROR
      NotifyImportFinishedWorker.new.perform @opml_import_job_state.id
      mail_should_not_be_sent
      expect(@opml_import_job_state.reload.state).to eq OpmlImportJobState::ERROR
    end

    it 'does nothing if the opml_import_job_state has state SUCCESS' do
      @opml_import_job_state.update state: OpmlImportJobState::SUCCESS
      NotifyImportFinishedWorker.new.perform @opml_import_job_state.id
      mail_should_not_be_sent
      expect(@opml_import_job_state.reload.state).to eq OpmlImportJobState::SUCCESS
    end
  end

  context 'finishes successfully' do

    it 'sets data import state to SUCCESS' do
      NotifyImportFinishedWorker.new.perform @opml_import_job_state.id
      @user.reload
      expect(@opml_import_job_state.reload.state).to eq OpmlImportJobState::SUCCESS
    end

    it 'sends a notification email' do
      NotifyImportFinishedWorker.new.perform @opml_import_job_state.id
      mail_should_be_sent 'Your feed subscriptions have been imported into', to: @user.email
    end

    it 'sends a notification email with failed feeds' do
      failed_url = 'http://some.failed.url.com'
      import_failure = FactoryBot.build :opml_import_failure, opml_import_job_state_id: @opml_import_job_state.id,
                                         url: failed_url
      @opml_import_job_state.opml_import_failures << import_failure

      NotifyImportFinishedWorker.new.perform @opml_import_job_state.id

      mail_should_be_sent 'We haven&#39;t been able to subscribe you to the following feeds', failed_url,
                          to: @user.email
    end

  end

  context 'finishes with an error' do

    before :each do
      allow(OPMLImportNotifier).to receive(:notify_success).and_raise StandardError.new
    end

    it 'sets data import state to ERROR if an error is raised' do
      expect {NotifyImportFinishedWorker.new.perform @opml_import_job_state.id}.to raise_error StandardError
      expect(@opml_import_job_state.reload.state).to eq OpmlImportJobState::ERROR
    end

    it 'sends an email' do
      expect {NotifyImportFinishedWorker.new.perform @opml_import_job_state.id}.to raise_error StandardError
      mail_should_be_sent 'There has been an error importing your feed subscriptions into', to: @user.email
    end

  end

end