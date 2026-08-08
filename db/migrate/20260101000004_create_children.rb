class CreateChildren < ActiveRecord::Migration[8.0]
  def change
    create_table :children do |t|
      t.references :family, null: false, foreign_key: true
      t.string :name, null: false
      t.date :birthdate
      t.string :color, null: false, default: "sky"
      t.string :emoji
      t.integer :points_balance, null: false, default: 0
      t.string :pin_digest
      t.integer :position, null: false, default: 0
      t.datetime :archived_at

      t.timestamps
    end

    add_index :children, [ :family_id, :position ]
    add_index :children, [ :family_id, :archived_at ]
  end
end
