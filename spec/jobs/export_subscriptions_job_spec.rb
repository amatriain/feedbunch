require 'spec_helper'

describe ExportSubscriptionsJob do

  before :each do
    @user = FactoryGirl.create :user

    @feed1 = FactoryGirl.create :feed
    @feed2 = FactoryGirl.create :feed
    @feed3 = FactoryGirl.create :feed
    @feed4 = FactoryGirl.create :feed

    @entry1 = FactoryGirl.build :entry, feed_id: @feed1.id
    @entry3 = FactoryGirl.build :entry, feed_id: @feed3.id
    @feed1.entries << @entry1
    @feed3.entries << @entry3

    @user.subscribe @feed1.fetch_url
    @user.subscribe @feed2.fetch_url
    @user.subscribe @feed3.fetch_url
    @user.subscribe @feed4.fetch_url

    @folder = FactoryGirl.build :folder, user_id: @user.id
    @user.folders << @folder
    @folder.feeds << @feed3 << @feed4

    time_now = Time.zone.parse '2000-01-01'
    ActiveSupport::TimeZone.any_instance.stub(:now).and_return time_now

    @opml = <<OPML_DOCUMENT
<?xml version="1.0" encoding="UTF-8"?>
<opml version="1.0">
  <head>
    <title>RSS subscriptions exported by Feedbunch (feedbunch.com)</title>
    <ownerName>#{@user.name}</ownerName>
    <ownerEmail>#{@user.email}</ownerEmail>
    <dateCreated>#{time_now.rfc822}</dateCreated>
  </head>
  <body>
    <outline type="rss" title="#{@feed1.title}" text="#{@feed1.title}" xmlUrl="#{@feed1.fetch_url}" htmlUrl="#{@feed1.url}"/>
    <outline type="rss" title="#{@feed2.title}" text="#{@feed2.title}" xmlUrl="#{@feed2.fetch_url}" htmlUrl="#{@feed2.url}"/>
    <outline title="#{@folder.title}" text="#{@folder.title}">
      <outline type="rss" title="#{@feed3.title}" text="#{@feed3.title}" xmlUrl="#{@feed3.fetch_url}" htmlUrl="#{@feed3.url}"/>
      <outline type="rss" title="#{@feed4.title}" text="#{@feed4.title}" xmlUrl="#{@feed4.fetch_url}" htmlUrl="#{@feed4.url}"/>
    </outline>
  </body>
</opml>
OPML_DOCUMENT

    Feedbunch::Application.config.uploads_manager.stub :save
    Feedbunch::Application.config.uploads_manager.stub :delete
  end

  after :each do
    uploaded_files = File.join Rails.root, 'uploads', '*.opml'
    Dir.glob(uploaded_files).each {|f| File.delete f}
  end

  context 'validations' do

    it 'does nothing if user does not exist' do
      ExportSubscriptionsJob.perform 1234567890
      Feedbunch::Application.config.uploads_manager.should_not receive(:save)
      Feedbunch::Application.config.uploads_manager.should_not receive(:delete)
    end
  end

  it 'uploads correct OPML file' do
    Feedbunch::Application.config.uploads_manager.should receive(:save) do |filename, content|
      filename.should eq "feedbunch_#{@user.email}.opml"
      content.should eq @opml
    end
    ExportSubscriptionsJob.perform @user.id
  end

  it 'deletes old OPML files for the user' do
    Feedbunch::Application.config.uploads_manager.stub(:exists?).and_return true
    Feedbunch::Application.config.uploads_manager.should receive(:delete).once do |filename|
      filename.should eq "feedbunch_#{@user.email}.opml"
    end
    ExportSubscriptionsJob.perform @user.id
  end

  it 'deletes OPML files when deleting a user' do
    Feedbunch::Application.config.uploads_manager.stub(:exists?).and_return true
    Feedbunch::Application.config.uploads_manager.should receive(:delete).once do |filename|
      filename.should eq "feedbunch_#{@user.email}.opml"
    end

    @user.destroy
  end

  it 'sends notification email if finished successfully' do
    ExportSubscriptionsJob.perform @user.id
    mail_should_be_sent to: @user.email, text: 'Your feed subscriptions have been exported by Feedbunch'
  end

  it 'sends notification email if finished with an error' do
    OPMLExporter.stub(:export).and_raise StandardError.new
    expect {ExportSubscriptionsJob.perform @user.id}.to raise_error
    mail_should_be_sent to: @user.email, text: 'There has been an error exporting your feed subscriptions from Feedbunch'
  end

end