class AddFailingSinceToFeeds < ActiveRecord::Migration[5.2]
  def change
    add_column :feeds, :failing_since, :datetime, null: true
  end
end
