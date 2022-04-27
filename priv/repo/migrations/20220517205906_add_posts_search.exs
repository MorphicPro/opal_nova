defmodule OpalNova.Repo.Migrations.AddPostsSearch do
  use Ecto.Migration

  def change do
    execute("""
    CREATE MATERIALIZED VIEW post_search_v2 AS
    SELECT
      posts.id AS id,
      posts.title AS title,
      posts.body AS body,
      posts.description AS description,
      (
      setweight(to_tsvector(unaccent(posts.title)), 'A') ||
      setweight(to_tsvector(unaccent(posts.description)), 'B') ||
      setweight(to_tsvector(unaccent(posts.body)), 'C')
      ) AS document
    FROM posts
    GROUP BY posts.id
    """)

    # to support full-text searches
    create index("post_search_v2", ["document"], using: :gin)

    # to support substring title matches with ILIKE
    execute(
      "CREATE INDEX post_search_v2_title_trgm_index ON post_search USING gin (title gin_trgm_ops)"
    )

    # to support updating CONCURRENTLY
    create unique_index("post_search_v2", [:id])

    execute("""
    CREATE OR REPLACE FUNCTION refresh_post_search()
    RETURNS TRIGGER LANGUAGE plpgsql
    AS $$
    BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY post_search_v2;
    RETURN NULL;
    END $$;
    """)

    execute("""
    CREATE TRIGGER refresh_post_search_v2
    AFTER INSERT OR UPDATE OR DELETE OR TRUNCATE
    ON posts
    FOR EACH STATEMENT
    EXECUTE PROCEDURE refresh_post_search();
    """)
  end
end
