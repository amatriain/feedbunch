class CreateEntryStates < ActiveRecord::Migration[5.2]
  def change
    create_table :entry_states do |t|
      t.boolean :read
      t.integer :user_id
      t.integer :entry_id

      t.timestamps
    end
  end
end
