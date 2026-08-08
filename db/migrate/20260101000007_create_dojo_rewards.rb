class CreateDojoRewards < ActiveRecord::Migration[8.0]
  def change
    create_table :dojo_rewards do |t|
      t.references :family, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :cost, null: false
      t.string :icon, null: false, default: "🎁"
      t.integer :position, null: false, default: 0
      t.datetime :archived_at

      t.timestamps
    end

    add_index :dojo_rewards, [ :family_id, :position ]
    add_index :dojo_rewards, [ :family_id, :archived_at ]
  end
end
