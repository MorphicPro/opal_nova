defmodule OpalNovaWeb.Admin.PostLive.FormComponent do
  use OpalNovaWeb, :live_component

  alias OpalNova.Blog
  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> allow_upload(:image,
       accept: ~w(.jpg .jpeg .png),
       max_entries: 1,
       external: &presign_upload/2
     )}
  end

  @impl true
  def update(%{post: post} = assigns, socket) do
    changeset = Blog.change_post(post)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  # defp presign_upload(entry, socket) do
  #   uploads = socket.assigns.uploads
  #   bucket = "opalnova"
  #   key = "#{entry.client_name}"

  #   config = %{
  #     region: "us-east-1",
  #     access_key_id: Application.get_env(:opal_nova, :simple_minio_uploader)[:access_key],
  #     secret_access_key: Application.get_env(:opal_nova, :simple_minio_uploader)[:secret_key]
  #   }

  #   {:ok, fields} =
  #     SimpleS3Upload.sign_form_upload(config, bucket,
  #       key: key,
  #       content_type: entry.client_type,
  #       max_file_size: uploads.image.max_file_size,
  #       expires_in: :timer.hours(1)
  #     )

  #   meta = %{
  #     uploader: "S3",
  #     key: key,
  #     url: "#{Application.get_env(:opal_nova, :simple_minio_uploader)[:host]}/#{bucket}/#{key}",
  #     fields: fields
  #   }

  #   {:ok, meta, socket}
  # end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    changeset =
      socket.assigns.post
      |> Blog.change_post(post_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("set-slug", _, %{assigns: %{post: post, changeset: changeset}} = socket) do
    title = changeset.changes |> Map.get(:title, post.title)

    changeset =
      socket.assigns.post
      |> Blog.change_post(changeset.changes |> Map.merge(%{slug: Slug.slugify(title)}))
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("set-slug", _, %{assigns: %{post: %{title: title} = post}} = socket) do
    changeset =
      socket.assigns.post
      |> Blog.change_post(post |> Map.merge(%{slug: Slug.slugify(title)}))
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    save_post(socket, socket.assigns.action, post_params)
  end

  def handle_event("cancel-upload", %{"ref" => ref, "value" => _value}, socket) do
    {:noreply, socket |> cancel_upload(:image, ref)}
  end

  defp save_post(socket, :edit, post_params) do
    case consume_uploaded_entries(socket, :image, fn %{url: url, md_url: md_url, sm_url: sm_url},
                                                     _ ->
           {:ok, [url, md_url, sm_url]}
         end) do
      [[url, md_url, sm_url]] ->
        image_map = %{"thumb_image" => sm_url, "cover_image" => md_url, "source_image" => url}

        case Blog.update_post(socket.assigns.post, Map.merge(post_params, image_map)) do
          {:ok, post} ->
            Phoenix.PubSub.broadcast(
              OpalNova.PubSub,
              "post:#{post.id}",
              {:post_edited, post}
            )

            {:noreply,
             socket
             |> put_flash(:info, "Post updated successfully")
             |> push_redirect(to: socket.assigns.return_to)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, :changeset, changeset)}
        end

      _ ->
        case Blog.update_post(socket.assigns.post, post_params) |> IO.inspect() do
          {:ok, post} ->
            Phoenix.PubSub.broadcast(
              OpalNova.PubSub,
              "post:#{post.id}",
              {:post_edited, post}
            )

            {:noreply,
             socket
             |> put_flash(:info, "Post updated successfully")
             |> push_redirect(to: socket.assigns.return_to)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, :changeset, changeset)}
        end
    end
  end

  defp save_post(socket, :new, post_params) do
    case consume_uploaded_entries(socket, :image, fn %{url: url, md_url: md_url, sm_url: sm_url},
                                                     _ ->
           {:ok, [url, md_url, sm_url]}
         end) do
      [[url, md_url, sm_url]] ->
        image_map = %{"thumb_image" => sm_url, "cover_image" => md_url, "source_image" => url}

        case Blog.create_post(Map.merge(post_params, image_map)) do
          {:ok, _post} ->
            {:noreply,
             socket
             |> put_flash(:info, "Post created successfully")
             |> push_redirect(to: socket.assigns.return_to)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, :changeset, changeset)}
        end

      _ ->
        case Blog.create_post(post_params) do
          {:ok, _post} ->
            {:noreply,
             socket
             |> put_flash(:info, "Post created successfully")
             |> push_redirect(to: socket.assigns.return_to)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, :changeset, changeset)}
        end
    end
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  defp presign_upload(entry, socket) do
    bucket = "opalnova"
    key = "#{entry.client_name}"
    host = Application.get_env(:opal_nova, :simple_minio_uploader)[:host]

    {:ok, full_string, md_string, sm_string} =
      %{
        region: "us-east-1",
        endpoint: host,
        access_key_id: Application.get_env(:opal_nova, :simple_minio_uploader)[:access_key],
        secret_access_key: Application.get_env(:opal_nova, :simple_minio_uploader)[:secret_key]
      }
      |> SimpleMinioUpload.sign_binary_upload(
        bucket: bucket,
        key: key,
        content_type: entry.client_type,
        expires_in: 3_600
      )

    meta = %{
      uploader: "S3",
      key: key,
      full_string: full_string,
      medium_string: md_string,
      small_string: sm_string,
      url: "#{host}/#{bucket}/#{key}",
      md_url: "#{host}/#{bucket}/md_#{key}",
      sm_url: "#{host}/#{bucket}/sm_#{key}"
    }

    {:ok, meta, socket}
  end
end
