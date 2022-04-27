defmodule OpalNova.Blog.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "comments" do
    field :flagged, :boolean, default: false
    field :message, :string
    field :post_id, :binary_id
    field :user_id, :binary_id
    field :name, :string
    field :captcha, :map, virtual: true
    field :captcha_return, :string, virtual: true

    timestamps()
  end

  @doc false
  def changeset(comment, attrs, captcha_text \\ "") do
    comment
    |> cast(attrs, [:message, :flagged, :captcha_return, :post_id, :name])
    |> validate_required([:message, :flagged, :captcha_return, :post_id, :name])
    |> validate_captcha(captcha_text)
    |> validate_required(:captcha_return)
    |> put_captcha()
  end

  defp validate_captcha(%{changes: %{captcha_return: captcha_return}} = cs, captcha_text) do
    if captcha_return == captcha_text do
      cs
    else
      cs
      |> delete_change(:captcha_return)
      |> add_error(:captcha_return, "captcha didn't match")
    end
  end

  defp validate_captcha(cs, _), do: cs

  defp put_captcha(%{valid?: false} = cs) do
    case OpalNova.Captcha.get() do
      {:ok, text, img_binary} ->
        # save text in session, then send img to client
        cs
        |> put_change(:captcha, %{image: img_binary, text: text})
        |> delete_change(:captcha_return)

      {:timeout} ->
        cs
        |> add_error(:captcha, "Issue generating captcha please reload page")
        |> delete_change(:captcha_return)

        # log some error
    end
  end

  defp put_captcha(cs) do
    delete_change(cs, :captcha_return)
  end
end
