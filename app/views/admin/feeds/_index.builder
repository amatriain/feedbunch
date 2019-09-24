# frozen_string_literal: true

context.instance_eval  do
  table_for(feeds, :sortable => true, :class => 'index_table') do |folder|
    selectable_column
    actions
    column :id
    column :title
    column :url
    column :fetch_url
    column :available
    column :last_fetched
    column :fetch_interval_secs
    column :failing_since
    column 'Entries' do |feed|
      feed.entries.count
    end
    actions
  end
end