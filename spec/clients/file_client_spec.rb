require 'spec_helper'

describe FileClient do

  before :each do
    @file_content = 'some_file_content'
    @filename = 'filename.txt'
    @filepath = File.join Rails.root, 'uploads', @filename
  end

  after :each do
    File.delete @filepath if FileTest.exists? @filepath
  end

  it 'saves file in uploads folder' do
    FileClient.save @filename, @file_content
    FileTest.exists?(@filepath).should be_true
  end

  it 'deletes file from uploads folder' do
    File.open(@filepath, 'w'){|f| f.write @file_content}

    FileClient.delete @filename
    FileTest.exists?(@filepath).should be_false
  end

  it 'reads file from uploads folder' do
    File.open(@filepath, 'w') {|f| f.write @file_content}

    contents = FileClient.read @filename
    contents.should eq @file_content
  end

  it 're-raises any errors' do
    error = StandardError.new
    File.stub(:open).and_raise error
    File.stub(:delete).and_raise error

    expect {FileClient.save @filename, @file_content}.to raise_error(StandardError)
    expect {FileClient.delete @filename}.to raise_error(StandardError)
  end

end