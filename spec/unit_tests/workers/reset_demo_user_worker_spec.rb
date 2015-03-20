require 'rails_helper'

describe ResetDemoUserWorker do

  before :each do
    Feedbunch::Application.config.demo_enabled = true
    @demo_email = Feedbunch::Application.config.demo_email
    @demo_password = Feedbunch::Application.config.demo_password
  end

  context 'create demo user' do

    context 'demo user enabled' do

      it 'creates demo user if it does not exist' do
        expect(User.find_by_email @demo_email).to be nil
        ResetDemoUserWorker.new.perform
        expect(User.find_by_email @demo_email).not_to be nil
      end

      it 'does not alter demo user if it exists' do
        demo_user = FactoryGirl.create :user, email: @demo_email, password: @demo_password

        expect(User.find_by_email @demo_email).not_to be nil
        ResetDemoUserWorker.new.perform
        expect(User.find_by_email @demo_email).to eq demo_user
      end
    end

    context 'demo user disabled' do

      before :each do
        Feedbunch::Application.config.demo_enabled = false
      end

      it 'does not create demo user' do
        expect(User.find_by_email @demo_email).to be nil
        ResetDemoUserWorker.new.perform
        expect(User.find_by_email @demo_email).to be nil
      end

      it 'destroys demo user if it exists' do
        demo_user = FactoryGirl.create :user, email: @demo_email, password: @demo_password

        expect(User.find_by_email @demo_email).not_to be nil
        ResetDemoUserWorker.new.perform
        expect(User.find_by_email @demo_email).to be nil
      end

    end
  end

  context 'reset demo user' do
    # TODO implement
  end

end