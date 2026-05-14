class CreateChatSessionsAndMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.timestamps
    end

    create_table :messages do |t|
      t.references :chat_session, null: false, foreign_key: true
      t.string :role, null: false
      t.text :content, null: false
      t.jsonb :citations, null: false, default: []
      t.timestamps
    end

    add_index :messages, [:chat_session_id, :created_at]
  end
end
