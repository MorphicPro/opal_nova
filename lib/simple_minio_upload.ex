defmodule SimpleMinioUpload do
  @moduledoc """
  Dependency-free MinIO Uploading
  https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-query-string-auth.html
  https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-post-example.html
  """

  @sign_v4_algo "AWS4-HMAC-SHA256"
  @unsigned_payload "UNSIGNED-PAYLOAD"

  @doc """
  Signs a binary upload.

  The configuration is a map which must contain the following keys:

    * `:region` - The AWS region, such as "us-east-1"
    * `:access_key_id` - The AWS access key id
    * `:secret_access_key` - The AWS secret access key

  Returns a full request string with query params to use with binary upload blob.

  ## Options

    * `:key` - The required key of the object to be uploaded.
    * `:expires_in` - The required expiration time in milliseconds from now
      before the signed upload expires.

  ## Examples

      config = %{
        endpoint: "https://play.min.io",
        region: "us-east-1",
        access_key_id: System.fetch_env!("AWS_ACCESS_KEY_ID"),
        secret_access_key: System.fetch_env!("AWS_SECRET_ACCESS_KEY")
      }

      {:ok, fields} =
        SimpleMinioUpload.sign_binary_upload(config,
          bucket: "mybucket",
          key: "public/my-file-name",
          link_expiry: 3_600
        )
  """
  def sign_binary_upload(%{endpoint: endpoint} = config, opts) do
    bucket = Keyword.fetch!(opts, :bucket)
    key = Keyword.fetch!(opts, :key)
    request_datetime = Keyword.get(opts, :request_datetime, DateTime.utc_now())
    link_expiry = Keyword.get(opts, :link_expiry, 3_600)
    credential = credential(config, request_datetime)

    main_uri =
      endpoint
      |> URI.parse()
      |> URI.merge("#{bucket}/#{key}")

    md_uri =
      endpoint
      |> URI.parse()
      |> URI.merge("#{bucket}/md_#{key}")

    sm_uri =
      endpoint
      |> URI.parse()
      |> URI.merge("#{bucket}/sm_#{key}")

    main_headers_to_sign = %{"Host" => remove_default_port(main_uri)}
    md_headers_to_sign = %{"Host" => remove_default_port(md_uri)}
    sm_headers_to_sign = %{"Host" => remove_default_port(sm_uri)}

    main_query =
      %{
        "X-Amz-Algorithm" => @sign_v4_algo,
        "X-Amz-Credential" => credential,
        "X-Amz-Date" => iso8601_datetime(request_datetime),
        "X-Amz-Expires" => to_string(link_expiry),
        "X-Amz-SignedHeaders" => get_signed_headers(main_headers_to_sign)
      }
      |> URI.encode_query()

    md_query =
      %{
        "X-Amz-Algorithm" => @sign_v4_algo,
        "X-Amz-Credential" => credential,
        "X-Amz-Date" => iso8601_datetime(request_datetime),
        "X-Amz-Expires" => to_string(link_expiry),
        "X-Amz-SignedHeaders" => get_signed_headers(md_headers_to_sign)
      }
      |> URI.encode_query()

    sm_query =
      %{
        "X-Amz-Algorithm" => @sign_v4_algo,
        "X-Amz-Credential" => credential,
        "X-Amz-Date" => iso8601_datetime(request_datetime),
        "X-Amz-Expires" => to_string(link_expiry),
        "X-Amz-SignedHeaders" => get_signed_headers(sm_headers_to_sign)
      }
      |> URI.encode_query()

    main_new_uri = Map.put(main_uri, :query, main_query)
    md_new_uri = Map.put(md_uri, :query, md_query)
    sm_new_uri = Map.put(sm_uri, :query, sm_query)

    main_string_to_sign =
      string_to_sign(
        config,
        get_canonical_rquest(:put, main_new_uri, main_headers_to_sign),
        request_datetime
      )

    md_string_to_sign =
      string_to_sign(
        config,
        get_canonical_rquest(:put, md_new_uri, md_headers_to_sign),
        request_datetime
      )

    sm_string_to_sign =
      string_to_sign(
        config,
        get_canonical_rquest(:put, sm_new_uri, sm_headers_to_sign),
        request_datetime
      )

    main_signature =
      signing_key(config, request_datetime)
      |> hmac(main_string_to_sign)
      |> hex_digest()

    md_signature =
      signing_key(config, request_datetime)
      |> hmac(md_string_to_sign)
      |> hex_digest()

    sm_signature =
      signing_key(config, request_datetime)
      |> hmac(sm_string_to_sign)
      |> hex_digest()

    {:ok, "#{URI.to_string(main_new_uri)}&X-Amz-Signature=#{main_signature}",
     "#{URI.to_string(md_new_uri)}&X-Amz-Signature=#{md_signature}",
     "#{URI.to_string(sm_new_uri)}&X-Amz-Signature=#{sm_signature}"}
  end

  defp credential(%{} = config, %DateTime{} = requested_at) do
    "#{config.access_key_id}/#{short_date(requested_at)}/#{config.region}/s3/aws4_request"
  end

  defp short_date(%DateTime{} = datetime) do
    datetime
    |> iso8601_date()
    |> String.slice(0..7)
  end

  defp remove_default_port(%URI{host: host, port: port}) when port in [80, 443],
    do: to_string(host)

  defp remove_default_port(%URI{host: host, port: port}),
    do: "#{host}:#{port}"

  defp get_signed_headers(headers) do
    headers
    |> Map.keys()
    |> Enum.map(&String.downcase/1)
    |> Enum.sort()
    |> Enum.join(";")
  end

  defp get_canonical_rquest(method, uri, headers) do
    [
      method |> Atom.to_string() |> String.upcase(),
      uri.path,
      uri.query
    ]
    |> Kernel.++(
      Enum.sort(headers)
      |> Enum.map(fn {k, v} ->
        "#{String.downcase(k)}:#{to_string(v) |> String.trim()}"
      end)
    )
    |> Kernel.++(["", get_signed_headers(headers), @unsigned_payload])
    |> Enum.join("\n")
  end

  defp signing_key(client, request_datetime) do
    "AWS4#{client.secret_access_key}"
    |> hmac(iso8601_date(request_datetime))
    |> hmac(client.region)
    |> hmac("s3")
    |> hmac("aws4_request")
  end

  defp string_to_sign(client, canonical_request, request_datetime) do
    [
      @sign_v4_algo,
      iso8601_datetime(request_datetime),
      get_scope(client, request_datetime),
      canonical_request
      |> sha256()
      |> hex_digest()
    ]
    |> Enum.join("\n")
  end

  defp get_scope(client, request_datetime) do
    [
      iso8601_date(request_datetime),
      client.region,
      "s3",
      "aws4_request"
    ]
    |> Enum.join("/")
  end

  defp iso8601_datetime(date), do: %{date | microsecond: {0, 0}} |> DateTime.to_iso8601(:basic)
  defp iso8601_date(datetime), do: datetime |> DateTime.to_date() |> Date.to_iso8601(:basic)
  defp hmac(key, data), do: :crypto.mac(:hmac, :sha256, key, data)
  defp sha256(data), do: :crypto.hash(:sha256, data)
  defp hex_digest(data), do: Base.encode16(data, case: :lower)
end
