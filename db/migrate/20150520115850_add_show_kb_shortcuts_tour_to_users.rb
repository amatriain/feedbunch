class AddShowKbShortcutsTourToUsers < ActiveRecord::Migration
  def change
    add_column :users, :show_kb_shortcuts_tour, :boolean, default: true, null: false

  end
end
