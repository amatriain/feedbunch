require 'spec_helper'

describe Api::RefreshFeedJobStatesController, type: :controller do

  before :each do
    @user = FactoryGirl.create :user
    @job_state_1 = FactoryGirl.build :refresh_feed_job_state, user_id: @user.id
    @job_state_2 = FactoryGirl.build :refresh_feed_job_state, user_id: @user.id
    @user.refresh_feed_job_states << @job_state_1 << @job_state_2

    login_user_for_unit @user
  end

  context 'GET index' do

    it 'returns refresh job state successfully' do
      get :index, format: :json
      response.status.should eq 200
    end

    it 'assigns the right job states' do
      get :index, format: :json
      assigns(:job_states).count.should eq 2
      assigns(:job_states).should include @job_state_1
      assigns(:job_states).should include @job_state_2
    end

  end

  context 'GET show' do

    it 'assigns the right job state' do
      get :show, id: @job_state_1.id, format: :json
      assigns(:job_state).should eq @job_state_1
    end

    it 'returns a 404 for a job state that does not belong to the user' do
      job_state_3 = FactoryGirl.create :refresh_feed_job_state
      get :show, id: job_state_3.id, format: :json
      response.status.should eq 404
    end

    it 'returns a 404 for a non-existing job state' do
      get :show, id: 1234567890, format: :json
      response.status.should eq 404
    end
  end

  context 'DELETE remove' do

    it 'returns 200' do
      delete :destroy, id: @job_state_1.id, format: :json
      response.should be_success
    end

    it 'deletes the job state' do
      delete :destroy, id: @job_state_1.id, format: :json
      RefreshFeedJobState.exists?(@job_state_1.id).should be false
    end

    it 'returns 404 if the job state does not exist' do
      delete :destroy, id: 1234567890, format: :json
      response.status.should eq 404
    end

    it 'returns 404 if the job state does not belong to the current user' do
      job_state_3 = FactoryGirl.create :refresh_feed_job_state
      delete :destroy, id: job_state_3.id, format: :json
      response.status.should eq 404
    end

    it 'returns 500 if there is a problem unsubscribing' do
      RefreshFeedJobState.any_instance.stub(:destroy).and_raise StandardError.new
      delete :destroy, id: @job_state_1.id, format: :json
      response.status.should eq 500
    end
  end

end