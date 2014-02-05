class AddFailingSinceToFeeds < ActiveRecord::Migration
  def change
    add_column :feeds, :failing_since, :datetime, null: true
  end
end
