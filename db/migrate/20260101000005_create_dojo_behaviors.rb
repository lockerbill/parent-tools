class CreateDojoBehaviors < ActiveRecord::Migration[8.0]
  def change
    create_table :dojo_behaviors do |t|
      t.references :family, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :points, null: false
      t.string :category, null: false, default: "positive"
      t.string :icon, null: false, default: "⭐"
      t.string :color, null: false, default: "emerald"
      t.integer :position, null: false, default: 0
      t.datetime :archived_at

      t.timestamps
    end

    add_index :dojo_behaviors, [ :family_id, :category, :position ], name: "index_dojo_behaviors_on_family_category_position"
    add_index :dojo_behaviors, [ :family_id, :archived_at ]
  end
end
