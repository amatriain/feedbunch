require 'spec_helper'

describe Api::RefreshFeedJobStatusesController do

  before :each do
    @user = FactoryGirl.create :user
    @job_status_1 = FactoryGirl.build :refresh_feed_job_status, user_id: @user.id
    @job_status_2 = FactoryGirl.build :refresh_feed_job_status, user_id: @user.id
    @user.refresh_feed_job_statuses << @job_status_1 << @job_status_2

    login_user_for_unit @user
  end

  context 'GET index' do

    it 'returns refresh job status successfully' do
      get :index, format: :json
      response.status.should eq 200
    end

    it 'assigns the right job statuses' do
      get :index, format: :json
      assigns(:job_statuses).count.should eq 2
      assigns(:job_statuses).should include @job_status_1
      assigns(:job_statuses).should include @job_status_2
    end

  end

  context 'GET show' do

    it 'assigns the right job status' do
      get :show, id: @job_status_1.id, format: :json
      assigns(:job_status).should eq @job_status_1
    end

    it 'returns a 404 for a job status that does not belong to the user' do
      job_status_3 = FactoryGirl.create :refresh_feed_job_status
      get :show, id: job_status_3.id, format: :json
      response.status.should eq 404
    end

    it 'returns a 404 for a non-existing job status' do
      get :show, id: 1234567890, format: :json
      response.status.should eq 404
    end
  end

end