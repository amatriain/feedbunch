# frozen_string_literal: true

context.instance_eval  do
  h2 'Subscribe jobs'
  table_for(jobs, :sortable => true, :class => 'index_table') do |job|
    column :id
    column 'Fetch URL' do |job|
      job.fetch_url
    end
    column 'Feed' do |job|
      link_to job.feed.title, "/admin/feeds/#{job.feed.id}" if job.feed.present?
    end
    column :state
    column :updated_at
  end
end