class CreateDojoPointEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :dojo_point_events do |t|
      t.references :child, null: false, foreign_key: true
      t.references :behavior, foreign_key: { to_table: :dojo_behaviors }
      t.references :user, foreign_key: true
      t.integer :points, null: false
      t.integer :requested_points, null: false
      t.string :label, null: false
      t.text :note
      t.datetime :occurred_at, null: false
      t.datetime :reverted_at

      t.timestamps
    end

    add_index :dojo_point_events, [ :child_id, :occurred_at ]
    add_index :dojo_point_events, [ :child_id, :reverted_at ]
    add_index :dojo_point_events, :occurred_at
  end
end
