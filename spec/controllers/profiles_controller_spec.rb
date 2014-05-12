require 'spec_helper'

describe Devise::ProfilesController do

  before :each do
    @user = FactoryGirl.create :user
    login_user_for_unit @user
  end

  context 'DELETE destroy' do

    it 'destroys user' do
      User.exists?(@user.id).should be_true
      delete :destroy, delete_user_registration: {password: @user.password}
      User.exists?(@user.id).should be_false
    end

    it 'does not destroy user if wrong password is submitted' do
      User.exists?(@user.id).should be_true
      delete :destroy, delete_user_registration: {password: 'wrong_password'}
      User.exists?(@user.id).should be_true
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
