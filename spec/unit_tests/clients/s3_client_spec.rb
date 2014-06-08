require 'rails_helper'

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
    allow(@s3_objects_mock).to receive(:[]).and_return @s3_object_mock
    @s3_bucket_mock = double 'bucket', objects: @s3_objects_mock
    @s3_buckets_mock = double 'buckets'
    allow(@s3_buckets_mock).to receive(:[]).and_return @s3_bucket_mock

    allow_any_instance_of(AWS::S3).to receive(:buckets).and_return @s3_buckets_mock
  end

  it 'uploads file to S3' do
    expect(@s3_objects_mock).to receive(:create).with(@s3_key, @file_content)
    S3Client.save @user, @upload_folder, @filename, @file_content
  end

  it 'deletes file from S3' do
    expect(@s3_object_mock).to receive :delete
    S3Client.delete @user, @upload_folder, @filename
  end

  it 'reads file from S3' do
    content = S3Client.read @user, @upload_folder, @filename
    expect(content).to eq @file_content
  end

  it 're-raises any errors' do
    error_message = 'AWS error'
    error = AWS::Errors::Base.new(error_message)
    allow_any_instance_of(AWS::S3).to receive(:buckets).and_raise error

    expect {S3Client.save @user, @upload_folder, @filename, @file_content}.to raise_error(AWS::Errors::Base, error_message)
    expect {S3Client.delete @user, @upload_folder, @filename}.to raise_error(AWS::Errors::Base, error_message)
  end

  it 'returns true if file exists' do
    exists = S3Client.exists? @user, @upload_folder, @filename
    expect(exists).to be true
  end

  it 'returns false if file does not exist' do
    allow(@s3_object_mock).to receive(:exists?).and_return false
    exists = S3Client.exists? @user, @upload_folder, @filename
    expect(exists).to be false
  end

end