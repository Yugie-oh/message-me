class CreateItems < ActiveRecord::Migration[5.2]
  def change
    create_table :items do |t|
      t.references :checklist, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :body, null: false
      t.boolean :done, null: false, default: false
      t.timestamps
    end
  end
end
