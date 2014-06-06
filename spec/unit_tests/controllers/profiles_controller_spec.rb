require 'rails_helper'

describe Devise::ProfilesController, type: :controller do

  before :each do
    @user = FactoryGirl.create :user
    login_user_for_unit @user
  end

  context 'DELETE destroy' do

    it 'locks user and enqueues job to destroy it' do
      Resque.should_receive(:enqueue).with DestroyUserJob, @user.id
      delete :destroy, delete_user_registration: {password: @user.password}
      @user.reload.access_locked?.should be true
    end

    it 'does not locl user nor enqueue job if wrong password is submitted' do
      Resque.should_not_receive :enqueue
      delete :destroy, delete_user_registration: {password: 'wrong_password'}
      @user.reload.access_locked?.should be false
    end

    it 'redirects to root path' do
      delete :destroy, delete_user_registration: {password: @user.password}
      response.should redirect_to root_path
    end

    it 'redirects to edit profile path if wrong password is submitted' do
      delete :destroy, delete_user_registration: {password: 'wrong_password'}
      response.should redirect_to edit_user_registration_path
    end
  end
end
