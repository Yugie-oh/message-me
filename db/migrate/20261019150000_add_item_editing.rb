class AddItemEditing < ActiveRecord::Migration[5.2]
  def change
    add_column :checklists, :edit_policy, :string, null: false, default: "everyone"

    add_reference :items, :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
    add_reference :items, :editing_by, foreign_key: { to_table: :users, on_delete: :nullify }
    add_column :items, :editing_at, :datetime
  end
end
