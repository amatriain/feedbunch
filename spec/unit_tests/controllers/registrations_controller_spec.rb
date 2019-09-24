# frozen_string_literal: true

require 'rails_helper'

describe FeedbunchAuth::RegistrationsController, type: :controller do

  context 'POST create' do

    before :each do
      @user = FactoryBot.build :user

      # Necessary for Devise to be able to detect mappings during testing. Not sure why but these tests fail if this line
      # is removed
      @request.env['devise.mapping'] = Devise.mappings[:user]
    end

    it 'returns redirect to signup success path' do
      post :create, params: {'user' => {'email'=>@user.email, 'name'=>@user.name, 'password'=>@user.password,
                               'password_confirmation'=>@user.password, 'locale'=>@user.locale,
                               'timezone'=>@user.timezone}}
      expect(response).to redirect_to signup_success_path
    end

    it 'does not destroy confirmed user' do
      @user.save!
      expect_any_instance_of(User).not_to receive :destroy
      post :create, params: {'user' => {'email'=>@user.email, 'name'=>@user.name, 'password'=>@user.password,
                               'password_confirmation'=>@user.password, 'locale'=>@user.locale,
                               'timezone'=>@user.timezone}}
      expect(response).to be_successful
    end

  end

  context 'DELETE destroy' do

    before :each do
      @user = FactoryBot.create :user
      login_user_for_unit @user
    end

    it 'locks user and enqueues job to destroy it' do
      expect(DestroyUserWorker.jobs.size).to eq 0

      delete :destroy, params: {delete_user_registration: {password: @user.password}}

      expect(DestroyUserWorker.jobs.size).to eq 1
      job = DestroyUserWorker.jobs.first
      expect(job['class']).to eq 'DestroyUserWorker'
      expect(job['args']).to eq [@user.id]

      expect(@user.reload.access_locked?).to be true
    end

    it 'does not lock user nor enqueue job if wrong password is submitted' do
      expect(DestroyUserWorker.jobs.size).to eq 0
      delete :destroy, params: {delete_user_registration: {password: 'wrong_password'}}
      expect(DestroyUserWorker.jobs.size).to eq 0
      expect(@user.reload.access_locked?).to be false
    end

    it 'redirects to root path' do
      delete :destroy, params: {delete_user_registration: {password: @user.password}}
      expect(response).to redirect_to root_path
    end

    it 'redirects to edit profile path if wrong password is submitted' do
      delete :destroy, params: {delete_user_registration: {password: 'wrong_password'}}
      expect(response).to redirect_to edit_user_registration_path
    end
  end

end
