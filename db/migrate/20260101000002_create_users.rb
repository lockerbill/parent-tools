class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.references :family, null: false, foreign_key: true
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :name, null: false
      t.string :role, null: false, default: "parent"

      t.timestamps
    end

    add_index :users, :email_address, unique: true
  end
end
