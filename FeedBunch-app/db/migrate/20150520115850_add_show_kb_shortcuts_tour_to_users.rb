class AddShowKbShortcutsTourToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :show_kb_shortcuts_tour, :boolean, default: true, null: false

  end
end
