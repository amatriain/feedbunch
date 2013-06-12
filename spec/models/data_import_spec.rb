require 'spec_helper'

describe DataImport do

  before :each do
    @user = FactoryGirl.create :user
    @data_import = FactoryGirl.build :data_import, user_id: @user.id
    @user.data_import = @data_import
  end

  context 'validations' do
    it 'always belongs to a user' do
      data_import = FactoryGirl.build :data_import, user_id: nil
      data_import.should_not be_valid
    end

    it 'requires a status' do
      data_import = FactoryGirl.build :data_import, status: nil
      data_import.should_not be_valid

      data_import = FactoryGirl.build :data_import, status: ''
      data_import.should_not be_valid
    end
  end

end
