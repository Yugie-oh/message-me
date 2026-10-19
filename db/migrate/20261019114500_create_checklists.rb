class CreateChecklists < ActiveRecord::Migration[5.2]
  def change
    create_table :checklists do |t|
      t.string :title, null: false
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
