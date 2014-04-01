require 'spec_helper'

describe Api::RefreshFeedJobStatusesController do

  before :each do
    @user = FactoryGirl.create :user
    job_status = FactoryGirl.build :refresh_feed_job_status, user_id: @user.id
    @user.refresh_feed_job_statuses << job_status

    login_user_for_unit @user
  end

  context 'GET show' do

    it 'returns refresh job status successfully' do
      get :show, format: :json
      response.status.should eq 200
    end

  end

end