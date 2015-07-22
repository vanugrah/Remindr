class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :user_ID
      t.string :first_name
      t.string :last_name
      t.string :user_name
      t.string :password_salt
      t.string :password_hash
      t.string :email
      t.string :phone_number
      t.string :service_provider

      t.timestamps null: false
    end
  end
end
