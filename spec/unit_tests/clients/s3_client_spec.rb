require 'spec_helper'

describe S3Client do

  before :each do
    @user = FactoryGirl.create :user
    @file_content = 'some_file_content'
    @filename = 'filename.txt'
    @upload_folder = OPMLImporter::FOLDER
    @s3_key = "#{@upload_folder}/#{@user.id.to_s}/#{@filename}"

    # Substitute the AWS S3 object that makes the call to the AWS API with
    # a mock object
    @s3_object_mock = double 'object', key: @s3_key, delete: nil, read: @file_content, exists?: true
    @s3_objects_mock = double 'objects', create: @s3_object_mock
    @s3_objects_mock.stub :[] => @s3_object_mock
    @s3_bucket_mock = double 'bucket', objects: @s3_objects_mock
    @s3_buckets_mock = double 'buckets'
    @s3_buckets_mock.stub :[] => @s3_bucket_mock

    AWS::S3.any_instance.stub buckets: @s3_buckets_mock
  end

  it 'uploads file to S3' do
    @s3_objects_mock.should_receive(:create).with(@s3_key, @file_content)
    S3Client.save @user, @upload_folder, @filename, @file_content
  end

  it 'deletes file from S3' do
    @s3_object_mock.should_receive :delete
    S3Client.delete @user, @upload_folder, @filename
  end

  it 'reads file from S3' do
    content = S3Client.read @user, @upload_folder, @filename
    content.should eq @file_content
  end

  it 're-raises any errors' do
    error_message = 'AWS error'
    error = AWS::Errors::Base.new(error_message)
    AWS::S3.any_instance.stub(:buckets).and_raise error

    expect {S3Client.save @user, @upload_folder, @filename, @file_content}.to raise_error(AWS::Errors::Base, error_message)
    expect {S3Client.delete @user, @upload_folder, @filename}.to raise_error(AWS::Errors::Base, error_message)
  end

  it 'returns true if file exists' do
    exists = S3Client.exists? @user, @upload_folder, @filename
    exists.should be true
  end

  it 'returns false if file does not exist' do
    @s3_object_mock.stub(:exists?).and_return false
    exists = S3Client.exists? @user, @upload_folder, @filename
    exists.should be false
  end

end