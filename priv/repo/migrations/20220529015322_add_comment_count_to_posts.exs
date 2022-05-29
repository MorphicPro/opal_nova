defmodule OpalNova.Repo.Migrations.AddCommentCountToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :comment_count, :integer, default: 0, null: false
    end
  end
end
