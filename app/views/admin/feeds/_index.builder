context.instance_eval  do
  table_for(feeds, :sortable => true, :class => 'index_table') do |folder|
    selectable_column
    default_actions
    column :id
    column :title
    column :url
    column :fetch_url
    column :available
    column :last_fetched
    column :fetch_interval_secs
    column :failing_since
    column :etag
    column :last_modified
    column 'Entries' do |feed|
      feed.entries.count
    end
    default_actions
  end
end