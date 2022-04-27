defmodule OpalNova.Repo.Migrations.AddNameToComments do
  use Ecto.Migration

  def change do
    alter table(:comments) do
      add :name, :string
    end
  end
end
