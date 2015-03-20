require 'rails_helper'

describe ResetDemoUserWorker do

  before :each do
    @demo_email = Feedbunch::Application.config.demo_email
    @demo_password = Feedbunch::Application.config.demo_password
  end

  context 'create demo user' do

    it 'creates demo user if it does not exist' do
      expect(User.find_by_email @demo_email).to be nil
      ResetDemoUserWorker.new.perform
      expect(User.find_by_email @demo_email).not_to be nil
    end
  end

  context 'reset demo user' do
    # TODO implement
  end

end