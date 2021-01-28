class AddKbShortcutsEnabledToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :kb_shortcuts_enabled, :boolean, null: false, default: true
  end
end
