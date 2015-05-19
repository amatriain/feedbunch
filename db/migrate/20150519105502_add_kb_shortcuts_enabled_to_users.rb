class AddKbShortcutsEnabledToUsers < ActiveRecord::Migration
  def change
    add_column :users, :kb_shortcuts_enabled, :boolean, null: false, default: true
  end
end
