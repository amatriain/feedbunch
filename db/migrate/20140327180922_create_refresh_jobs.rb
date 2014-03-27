class CreateRefreshJobs < ActiveRecord::Migration
  def change
    create_table :refresh_jobs do |t|
      t.integer :user_id, null: false
      t.integer :feed_id, null: false
      t.text :status, null: false
      t.timestamps
    end
  end
end
