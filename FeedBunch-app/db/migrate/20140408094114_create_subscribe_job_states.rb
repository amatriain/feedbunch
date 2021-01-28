class CreateSubscribeJobStates < ActiveRecord::Migration[5.2]
  def change
    create_table :subscribe_job_states do |t|
      t.integer :user_id, null: false
      t.text :state,      null: false
      t.text :fetch_url, null: false
      t.timestamps
    end
  end
end
