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
    @s3_object_mock = double 'object', key: @s3_key, delete: nil, get: @file_content, exists?: true
    @s3_bucket_mock = double 'bucket', put_object: @s3_object_mock, object: @s3_object_mock
    @s3_resource_mock = double 'resource', bucket: @s3_bucket_mock

    allow(Aws::S3::Resource).to receive(:new).and_return @s3_resource_mock
  end

  it 'uploads file to S3' do
    expect(@s3_bucket_mock).to receive(:put_object).with key: @s3_key, body: @file_content
    S3Client.save @user.id, @upload_folder, @filename, @file_content
  end

  it 'deletes file from S3' do
    expect(@s3_object_mock).to receive :delete
    S3Client.delete @user.id, @upload_folder, @filename
  end

  it 'reads file from S3' do
    content = S3Client.read @user.id, @upload_folder, @filename
    expect(content).to eq @file_content
  end

  it 're-raises any errors' do
    error_message = 'AWS error'
    error = StandardError.new
    allow(@s3_resource_mock).to receive(:bucket).and_raise error

    expect {S3Client.save @user.id, @upload_folder, @filename, @file_content}.to raise_error StandardError
    expect {S3Client.delete @user.id, @upload_folder, @filename}.to raise_error StandardError
  end

  it 'returns true if file exists' do
    exists = S3Client.exists? @user.id, @upload_folder, @filename
    expect(exists).to be true
  end

  it 'returns false if file does not exist' do
    allow(@s3_object_mock).to receive(:exists?).and_return false
    exists = S3Client.exists? @user.id, @upload_folder, @filename
    expect(exists).to be false
  end

end