require 'rails_helper'

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
    expect(FileTest.exists?(@filepath)).to be true
  end

  it 'deletes file from uploads folder' do
    FileUtils.mkdir_p File.dirname(@filepath)
    File.open(@filepath, 'w'){|f| f.write @file_content}

    FileClient.delete @user, @upload_folder, @filename
    expect(FileTest.exists?(@filepath)).to be false
  end

  it 'reads file from uploads folder' do
    FileUtils.mkdir_p File.dirname(@filepath)
    File.open(@filepath, 'w') {|f| f.write @file_content}

    contents = FileClient.read @user, @upload_folder, @filename
    expect(contents).to eq @file_content
  end

  it 're-raises any errors' do
    FileUtils.mkdir_p File.dirname(@filepath)
    File.open(@filepath, 'w') {|f| f.write @file_content}
    error = StandardError.new
    allow(File).to receive(:open).and_raise error
    allow(File).to receive(:delete).and_raise error

    expect {FileClient.save @user, @upload_folder, @filename, @file_content}.to raise_error(StandardError)
    expect {FileClient.delete @user, @upload_folder, @filename}.to raise_error(StandardError)
  end

  it 'returns true if file exists' do
    FileClient.save @user, @upload_folder, @filename, @file_content
    expect(FileClient.exists?(@user, @upload_folder, @filename)).to be true
  end

  it 'returns false if file does not exist' do
    expect(FileClient.exists?(@user, @upload_folder, @filename)).to be false
  end

end