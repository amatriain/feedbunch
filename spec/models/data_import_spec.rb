require 'spec_helper'

describe DataImport do

  before :each do
    @user = FactoryGirl.create :user
  end

  context 'validations' do

    it 'always belongs to a user' do
      data_import = FactoryGirl.build :data_import, user_id: nil
      data_import.should_not be_valid
    end
  end

  context 'default values' do

    it 'defaults to status RUNNING when created' do
      @user.create_data_import

      @user.data_import.status.should eq DataImport::RUNNING
    end

    it 'defaults to zero total_feeds' do
      data_import = FactoryGirl.create :data_import, total_feeds: nil
      data_import.total_feeds.should eq 0
    end

    it 'defaults to zero processed_feeds' do
      data_import = FactoryGirl.create :data_import, processed_feeds: nil
      data_import.processed_feeds.should eq 0
    end

    it 'defaults show_alert to true' do
      data_import = FactoryGirl.build :data_import, show_alert: nil
      data_import.save!
      data_import.show_alert.should be_true
    end

  end

end
