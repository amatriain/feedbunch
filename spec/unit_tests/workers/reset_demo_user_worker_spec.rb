require 'rails_helper'

describe ResetDemoUserWorker do

  context 'create demo user' do

    it 'creates demo user if it does not exist' do
      expect(User.find_by_email ResetDemoUserWorker::DEMO_EMAIL).to be nil
      ResetDemoUserWorker.new.perform
      expect(User.find_by_email ResetDemoUserWorker::DEMO_EMAIL).not_to be nil
    end

    it 'allows login by the demo user', js: true do

    end
  end

end