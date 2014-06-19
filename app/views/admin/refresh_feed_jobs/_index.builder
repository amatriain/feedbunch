context.instance_eval  do
  h2 'Refresh feed jobs'
  table_for(jobs, :sortable => true, :class => 'index_table') do |job|
    column :id
    column 'Feed id' do |job|
      job.feed.id
    end
    column 'Feed' do |job|
      link_to job.feed.title, "/admin/feeds/#{job.feed.id}"
    end
    column :state
    column :updated_at
  end
end