require 'spec_helper'

describe S3Client do

  before :each do
    @file_content = 'some_file_content'
    @filename = 'filename.txt'
    @s3_key = 'some/s3/key'

    # Substitute the AWS S3 object that makes the call to the AWS API with
    # a mock object
    @s3_object_mock = double 'object', key: @s3_key, delete: nil
    @s3_objects_mock = double 'objects', create: @s3_object_mock
    @s3_objects_mock.stub :[] => @s3_object_mock
    @s3_bucket_mock = double 'bucket', objects: @s3_objects_mock
    @s3_buckets_mock = double 'buckets'
    @s3_buckets_mock.stub :[] => @s3_bucket_mock

    AWS::S3.any_instance.stub buckets: @s3_buckets_mock
  end

  it 'uploads file to S3' do
    @s3_objects_mock.should_receive(:create).with("uploads/#{@filename}", @file_content)
    S3Client.save @filename, @file_content
  end

  it 'deletes file from S3' do
    @s3_object_mock.should_receive :delete
    S3Client.delete @filename
  end

  it 're-raises any exceptions' do
    error_message = 'AWS error'
    error = AWS::Errors::Base.new(error_message)
    AWS::S3.any_instance.stub(:buckets).and_raise error

    expect {S3Client.save @filename, @file_content}.to raise_error(AWS::Errors::Base, error_message)
    expect {S3Client.delete @filename}.to raise_error(AWS::Errors::Base, error_message)
  end

end