require 'spec_helper'

describe FileClient do

  before :each do
    @file_content = 'some_file_content'
    @filename = 'filename.txt'
    @upload_folder = OPMLImporter::FOLDER
    @user = FactoryGirl.create :user
    @filepath = File.join Rails.root, @upload_folder, @user.id.to_s, @filename
  end

  after :each do
    upload_dir = File.join Rails.root, @upload_folder, @user.id.to_s
    FileUtils.rm_rf upload_dir if File.directory? upload_dir
  end

  it 'saves file in some folder' do
    FileClient.save @user, @upload_folder, @filename, @file_content
    FileTest.exists?(@filepath).should be_true
  end

  it 'deletes file from uploads folder' do
    FileUtils.mkdir_p File.dirname(@filepath)
    File.open(@filepath, 'w'){|f| f.write @file_content}

    FileClient.delete @user, @upload_folder, @filename
    FileTest.exists?(@filepath).should be_false
  end

  it 'reads file from uploads folder' do
    FileUtils.mkdir_p File.dirname(@filepath)
    File.open(@filepath, 'w') {|f| f.write @file_content}

    contents = FileClient.read @user, @upload_folder, @filename
    contents.should eq @file_content
  end

  it 're-raises any errors' do
    FileUtils.mkdir_p File.dirname(@filepath)
    File.open(@filepath, 'w') {|f| f.write @file_content}
    error = StandardError.new
    File.stub(:open).and_raise error
    File.stub(:delete).and_raise error

    expect {FileClient.save @user, @upload_folder, @filename, @file_content}.to raise_error(StandardError)
    expect {FileClient.delete @user, @upload_folder, @filename}.to raise_error(StandardError)
  end

  it 'returns true if file exists' do
    FileClient.save @user, @upload_folder, @filename, @file_content
    FileClient.exists?(@user, @upload_folder, @filename).should be_true
  end

  it 'returns false if file does not exist' do
    FileClient.exists?(@user, @upload_folder, @filename).should be_false
  end

end