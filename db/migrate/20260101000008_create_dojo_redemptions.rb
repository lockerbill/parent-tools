class CreateDojoRedemptions < ActiveRecord::Migration[8.0]
  def change
    create_table :dojo_redemptions do |t|
      t.references :child, null: false, foreign_key: true
      t.references :reward, null: false, foreign_key: { to_table: :dojo_rewards }
      t.references :user, foreign_key: true
      t.integer :cost, null: false
      t.string :status, null: false, default: "requested"
      t.text :note
      t.datetime :decided_at
      t.datetime :fulfilled_at

      t.timestamps
    end

    add_index :dojo_redemptions, [ :child_id, :status ]
    add_index :dojo_redemptions, :status
  end
end
