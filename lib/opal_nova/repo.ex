defmodule OpalNova.Repo do
  use Ecto.Repo,
    otp_app: :opal_nova,
    adapter: Ecto.Adapters.Postgres

  import Ecto.Query

  def by_slug(query, slug) do
    from(
      q in query,
      where: q.slug == ^slug
    )
  end

  def by_id(query, id) do
    from(
      q in query,
      where: q.id == ^id
    )
  end

  def where_published(query) do
    from(
      q in query,
      where: q.published_at <= ^Date.utc_today(),
      where: q.draft == false
    )
  end

  def order_by_published_at(query) do
    from(
      q in query,
      order_by: [desc: :published_at, desc: :inserted_at]
    )
  end
end
