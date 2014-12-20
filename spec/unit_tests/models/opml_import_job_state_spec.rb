require 'rails_helper'

describe OpmlImportJobState, type: :model do

  before :each do
    @user = FactoryGirl.create :user
  end

  context 'validations' do

    it 'always belongs to a user' do
      opml_import_job_state = FactoryGirl.build :opml_import_job_state, user_id: nil
      expect(opml_import_job_state).not_to be_valid
    end
  end

  context 'default values' do

    it 'defaults to state NONE when created' do
      @user.create_opml_import_job_state
      expect(@user.opml_import_job_state.state).to eq OpmlImportJobState::NONE
    end

    it 'defaults to zero total_feeds' do
      opml_import_job_state = FactoryGirl.create :opml_import_job_state, total_feeds: nil
      expect(opml_import_job_state.total_feeds).to eq 0
    end

    it 'defaults to zero processed_feeds' do
      opml_import_job_state = FactoryGirl.create :opml_import_job_state, processed_feeds: nil
      expect(opml_import_job_state.processed_feeds).to eq 0
    end

    it 'defaults show_alert to true' do
      opml_import_job_state = FactoryGirl.build :opml_import_job_state, show_alert: nil
      opml_import_job_state.save!
      expect(opml_import_job_state.show_alert).to be true
    end

  end

  context 'relationship with OpmlImportFailures' do

    before :each do
      @job_state = FactoryGirl.create :opml_import_job_state
    end

    it 'destroys associated OpmlImportFailure instances when destroyed' do
      import_failure_1 = FactoryGirl.build :opml_import_failure, opml_import_job_state_id: @job_state.id
      import_failure_2 = FactoryGirl.build :opml_import_failure, opml_import_job_state_id: @job_state.id
      @job_state.opml_import_failures << import_failure_1 << import_failure_2

      expect(OpmlImportFailure.all.count).to eq 2
      @job_state.destroy
      expect(OpmlImportFailure.all.count).to eq 0
    end

    it 'does not destroy OpmlImportFailure instances associated with other jobs' do
      job_state_2 = FactoryGirl.create :opml_import_job_state
      import_failure_1 = FactoryGirl.build :opml_import_failure, opml_import_job_state_id: job_state_2.id
      import_failure_2 = FactoryGirl.build :opml_import_failure, opml_import_job_state_id: job_state_2.id
      job_state_2.opml_import_failures << import_failure_1 << import_failure_2

      expect(OpmlImportFailure.all.count).to eq 2
      @job_state.destroy
      expect(OpmlImportFailure.all.count).to eq 2
    end
  end

end
