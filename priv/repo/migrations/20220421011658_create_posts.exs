defmodule OpalNova.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :body, :text
      add :description, :string
      add :published_at, :date
      add :draft, :boolean, default: false, null: false

      timestamps()
    end
  end
end
