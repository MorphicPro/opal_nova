defmodule OpalNova.Repo.Migrations.AddImagePathsToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :source_image, :string
      add :thumb_image, :string
    end
  end
end
