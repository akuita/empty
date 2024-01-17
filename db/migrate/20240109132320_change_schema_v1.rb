class ChangeSchemaV1 < ActiveRecord::Migration[6.0]
  def change
    create_table :users, comment: 'Stores user account information' do |t|
      t.string :email

      t.boolean :email_confirmed

      t.string :password_hash

      t.timestamps null: false
    end

    create_table :email_confirmation_tokens, comment: 'Stores tokens for email confirmation process' do |t|
      t.string :token

      t.datetime :expires_at

      t.timestamps null: false
    end

    add_reference :email_confirmation_tokens, :user, foreign_key: true
  end
end
