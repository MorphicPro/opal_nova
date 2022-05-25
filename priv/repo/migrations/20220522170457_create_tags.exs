defmodule OpalNova.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :text, null: false)
    end

    create(index(:tags, ["lower(name)"], unique: true))

    create table(:post_tags) do
      add(:tag_id, references(:tags, name: "tags_id_fkey", type: :uuid))
      add(:post_id, references(:posts, on_delete: :nothing, name: "posts_id_fkey", type: :uuid))
    end

    create(index(:post_tags, [:tag_id, :post_id], unique: true))
  end
end
