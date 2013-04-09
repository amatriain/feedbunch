def login_user_for_unit
  @request.env['devise.mapping'] = Devise.mappings[:user]
  user = FactoryGirl.create(:user)
  sign_in user
end