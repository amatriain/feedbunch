require 'rails_helper'

describe Api::SubscribeJobStatesController, type: :controller do

  before :each do
    @user = FactoryBot.create :user
    @job_state_1 = FactoryBot.build :subscribe_job_state, user_id: @user.id
    @job_state_2 = FactoryBot.build :subscribe_job_state, user_id: @user.id
    @user.subscribe_job_states << @job_state_1 << @job_state_2

    login_user_for_unit @user
  end

  context 'GET index' do

    it 'returns subscribe job state successfully' do
      get :index, format: :json
      expect(response.status).to eq 200
    end

    it 'assigns the right job states' do
      get :index, format: :json
      expect(assigns(:job_states).count).to eq 2
      expect(assigns(:job_states)).to include @job_state_1
      expect(assigns(:job_states)).to include @job_state_2
    end

  end

  context 'GET show' do

    it 'assigns the right job state' do
      get :show, params: {id: @job_state_1.id}, format: :json
      expect(assigns(:job_state)).to eq @job_state_1
    end

    it 'returns a 404 for a job state that does not belong to the user' do
      job_state_3 = FactoryBot.create :subscribe_job_state
      get :show, params: {id: job_state_3.id}, format: :json
      expect(response.status).to eq 404
    end

    it 'returns a 404 for a non-existing job state' do
      get :show, params: {id: 1234567890}, format: :json
      expect(response.status).to eq 404
    end
  end

  context 'DELETE remove' do

    it 'returns 200' do
      delete :destroy, params: {id: @job_state_1.id}, format: :json
      expect(response).to be_success
    end

    it 'deletes the job state' do
      delete :destroy, params: {id: @job_state_1.id}, format: :json
      expect(SubscribeJobState.exists?(@job_state_1.id)).to be false
    end

    it 'returns 404 if the job state does not exist' do
      delete :destroy, params: {id: 1234567890}, format: :json
      expect(response.status).to eq 404
    end

    it 'returns 404 if the job state does not belong to the current user' do
      job_state_3 = FactoryBot.create :subscribe_job_state
      delete :destroy, params: {id: job_state_3.id}, format: :json
      expect(response.status).to eq 404
    end

    it 'returns 500 if there is a problem unsubscribing' do
      allow_any_instance_of(SubscribeJobState).to receive(:destroy).and_raise StandardError.new
      delete :destroy, params: {id: @job_state_1.id}, format: :json
      expect(response.status).to eq 500
    end
  end

end