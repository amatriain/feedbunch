# frozen_string_literal: true

require 'rails_helper'

describe OpmlExportJobState, type: :model do

  before :each do
    @user = FactoryBot.create :user
    @filename = 'some_filename.opml'
  end

  context 'validations' do

    it 'always belongs to a user' do
      opml_export_job_state = FactoryBot.build :opml_export_job_state, user_id: nil
      expect(opml_export_job_state).not_to be_valid
    end

    it 'has filename if it has state SUCCESS' do
      opml_export_job_state = FactoryBot.build :opml_export_job_state, user_id: @user.id,
                                                state: OpmlExportJobState::SUCCESS,
                                                filename: nil,
                                                export_date: Time.zone.now
      expect(opml_export_job_state).not_to be_valid

      opml_export_job_state = FactoryBot.build :opml_export_job_state, user_id: @user.id,
                                                state: OpmlExportJobState::SUCCESS,
                                                filename: @filename,
                                                export_date: Time.zone.now
      expect(opml_export_job_state).to be_valid
    end

    it 'does not have a filename if it has state NONE' do
      opml_export_job_state = FactoryBot.build :opml_export_job_state, user_id: @user.id,
                                                state: OpmlExportJobState::NONE,
                                                filename: @filename
      opml_export_job_state.save!
      expect(opml_export_job_state.filename).to be_nil
    end

    it 'does not have a filename if it has state RUNNING' do
      opml_export_job_state = FactoryBot.build :opml_export_job_state, user_id: @user.id,
                                                state: OpmlExportJobState::RUNNING,
                                                filename: @filename
      opml_export_job_state.save!
      expect(opml_export_job_state.filename).to be_nil
    end

    it 'does not have a filename if it has state ERROR' do
      opml_export_job_state = FactoryBot.build :opml_export_job_state, user_id: @user.id,
                                                state: OpmlExportJobState::ERROR,
                                                filename: @filename
      opml_export_job_state.save!
      expect(opml_export_job_state.filename).to be_nil
    end

    it 'has export_date if it has state SUCCESS' do
      opml_export_job_state = FactoryBot.build :opml_export_job_state, user_id: @user.id,
                                                state: OpmlExportJobState::SUCCESS,
                                                export_date: nil
      expect(opml_export_job_state).not_to be_valid

      opml_export_job_state = FactoryBot.build :opml_export_job_state, user_id: @user.id,
                                                state: OpmlExportJobState::SUCCESS,
                                                export_date: Time.zone.now
      expect(opml_export_job_state).to be_valid
    end

    it 'does not have an export_date if it has state NONE' do
      opml_export_job_state = FactoryBot.build :opml_export_job_state, user_id: @user.id,
                                                state: OpmlExportJobState::NONE,
                                                export_date: Time.zone.now
      opml_export_job_state.save!
      expect(opml_export_job_state.export_date).to be_nil
    end

    it 'does not have an export_date if it has state RUNNING' do
      opml_export_job_state = FactoryBot.build :opml_export_job_state, user_id: @user.id,
                                                state: OpmlExportJobState::RUNNING,
                                                export_date: Time.zone.now
      opml_export_job_state.save!
      expect(opml_export_job_state.export_date).to be_nil
    end

    it 'does not have an export_date if it has state ERROR' do
      opml_export_job_state = FactoryBot.build :opml_export_job_state, user_id: @user.id,
                                                state: OpmlExportJobState::ERROR,
                                                export_date: Time.zone.now
      opml_export_job_state.save!
      expect(opml_export_job_state.export_date).to be_nil
    end
  end

  context 'default values' do

    it 'defaults to state NONE when created' do
      @user.create_opml_export_job_state
      expect(@user.opml_export_job_state.state).to eq OpmlExportJobState::NONE
    end

    it 'defaults show_alert to true' do
      opml_export_job_state = FactoryBot.build :opml_export_job_state, show_alert: nil
      opml_export_job_state.save!
      expect(opml_export_job_state.show_alert).to be true
    end
  end

  it 'deletes OPML file when deleting a opml_export_job_state' do
    filename = 'some_filename.opml'
    @user.create_opml_export_job_state
    @user.opml_export_job_state.update state: OpmlExportJobState::SUCCESS,
                                       filename: filename,
                                       export_date: Time.zone.now
    allow(Feedbunch::Application.config.uploads_manager).to receive(:exists?).and_return true
    expect(Feedbunch::Application.config.uploads_manager).to receive(:delete).once do |user_id, folder, file|
      expect(user_id).to eq @user.id
      expect(folder).to eq OpmlExporter::FOLDER
      expect(file).to eq filename
    end

    @user.opml_export_job_state.destroy
  end

end
