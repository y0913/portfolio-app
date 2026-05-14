class CreateDocumentsAndChunks < ActiveRecord::Migration[8.1]
  def up
    create_table :documents do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.string :status, null: false, default: "pending"
      t.timestamps
    end

    create_table :document_chunks do |t|
      t.references :document, null: false, foreign_key: true
      t.text :content, null: false
      t.integer :position, null: false
      t.string :embedding_model, null: false
      t.timestamps
    end

    execute "ALTER TABLE document_chunks ADD COLUMN embedding vector(1024);"

    add_index :document_chunks, [:document_id, :position], unique: true
    execute <<~SQL
      CREATE INDEX document_chunks_embedding_hnsw_idx
        ON document_chunks
        USING hnsw (embedding vector_cosine_ops);
    SQL
  end

  def down
    drop_table :document_chunks
    drop_table :documents
  end
end
