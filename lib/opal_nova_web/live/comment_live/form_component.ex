defmodule OpalNovaWeb.CommentLive.FormComponent do
  use OpalNovaWeb, :live_component

  alias OpalNova.Blog

  @impl true
  def update(%{comment: comment} = assigns, socket) do
    %{changes: %{captcha: %{text: text}}} = changeset = Blog.change_comment(comment)

    {:ok,
     socket
     |> Map.put(:private, socket.private |> Map.put(:captcha_text, text))
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event(
        "save",
        %{"comment" => comment_params},
        %{assigns: %{post_id: post_id}, private: %{captcha_text: captcha_text}} = socket
      ) do
    %{changes: %{captcha: %{text: text}}} =
      reset_changeset = Blog.change_comment(%OpalNova.Blog.Comment{})

    case Blog.create_comment(comment_params |> Map.merge(%{"post_id" => post_id}), captcha_text) do
      {:ok, comment} ->
        Phoenix.PubSub.broadcast(
          OpalNova.PubSub,
          "post:#{post_id}",
          {:new_comment, comment}
        )

        {:noreply,
         socket
         |> put_flash(:info, "Comment created successfully")
         |> Map.put(:private, socket.private |> Map.put(:captcha_text, text))
         |> assign(:changeset, reset_changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         assign(
           socket |> Map.put(:private, socket.private |> Map.put(:captcha_text, text)),
           :changeset,
           changeset
           |> Ecto.Changeset.put_change(:captcha, reset_changeset.changes.captcha)
         )}
    end
  end

  def image(data) do
    pic = Base.encode64(data)

    "<img class=\"m-0 mr-2\" src=\"data:image/gif;base64," <>
      pic <> "\" height=\"50\" />"
  end
end
