class AddJsonbSearchIndexes < ActiveRecord::Migration[7.2]
  def up
    # Enable pg_trgm for trigram indexes if we decide to add them later
    enable_extension "pg_trgm" unless extension_enabled?("pg_trgm")

    # JSONB containment/exists queries on page_specific_data
    add_index :page_pods, :page_specific_data, using: :gin, name: "index_page_pods_on_page_specific_data"

    # Full-text search support over JSONB contents for pods.definition
    execute <<~SQL
      CREATE INDEX IF NOT EXISTS index_pods_on_definition_tsv
      ON pods
      USING gin (
        to_tsvector('simple', coalesce(definition::text, ''))
      );
    SQL

    # Optional: full-text search over page_specific_data, useful for page-level overrides
    execute <<~SQL
      CREATE INDEX IF NOT EXISTS index_page_pods_on_page_specific_data_tsv
      ON page_pods
      USING gin (
        to_tsvector('simple', coalesce(page_specific_data::text, ''))
      );
    SQL
  end

  def down
    if index_exists?(:page_pods, :page_specific_data, name: "index_page_pods_on_page_specific_data")
      remove_index :page_pods, name: "index_page_pods_on_page_specific_data"
    end

    execute <<~SQL
      DROP INDEX IF EXISTS index_pods_on_definition_tsv;
    SQL

    execute <<~SQL
      DROP INDEX IF EXISTS index_page_pods_on_page_specific_data_tsv;
    SQL

    # Do not disable pg_trgm extension in down; it's harmless if left enabled and may be used elsewhere
  end
end
