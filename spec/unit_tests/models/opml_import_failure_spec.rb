require 'rails_helper'

describe OpmlImportFailure, type: :model do

  before :each do
    @import_failure = FactoryGirl.create :opml_import_failure
  end

  context 'validations' do

    it 'always belongs to an OpmlImportJobState' do
      import_failure = FactoryGirl.build :opml_import_failure, opml_import_job_state_id: nil
      expect(import_failure).not_to be_valid
    end

    it 'does not accept duplicate urls for the same job state' do
      import_failure_dupe = FactoryGirl.build :opml_import_failure, url: @import_failure.url,
                                              opml_import_job_state_id: @import_failure.opml_import_job_state.id
      expect(import_failure_dupe).not_to be_valid
    end

    it 'does accept duplicate urls for different job states' do
      job_state_2 = FactoryGirl.create :opml_import_job_state
      import_failure_dupe = FactoryGirl.build :opml_import_failure, url: @import_failure.url,
                                              opml_import_job_state_id: job_state_2.id
      expect(import_failure_dupe).to be_valid
    end
  end

end
