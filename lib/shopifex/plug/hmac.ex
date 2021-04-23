defmodule Shopify.Hmac do
  def valid_conn?(%{params: params} = _conn) when is_map(params) do
    hmac = String.upcase(params["hmac"])
    our_hmac = Shopify.Hmac.hmac_map(params)

    IO.puts("HMAC REQUEST: #{hmac}")
    IO.puts("HMAC CALCULATED: #{our_hmac}")
    our_hmac == hmac
  end

  def hmac_raw_body(body) do
    :crypto.hmac(
      :sha256,
      Application.fetch_env!(:shopifex, :secret),
      body
    )
    |> Base.encode64()
  end

  def hmac_map(params) when is_map(params) do
    query_string =
      params
      |> Map.delete("hmac")
      |> Map.delete("signature")
      |> update_ids()
      |> Enum.map(fn {key, value} ->
        "#{key}=#{value}"
      end)
      |> Enum.join("&")

    :crypto.hmac(
      :sha256,
      Application.fetch_env!(:shopifex, :secret),
      query_string
    )
    |> Base.encode16()
  end

  defp update_ids(%{"ids" => ids} = map) do
    # https://community.shopify.com/c/Shopify-Apps/Hmac-Verification-for-Bulk-Actions/td-p/587594
    # The shopify hmac algorithm does format the ids like
    # &ids=["1", "2"]
    # There must be a space between the 'elements'
    # ["1", "2"] |> inspect #=> "[\"1\", \"2\"]"
    %{map | "ids" => inspect(ids)}
  end

  defp update_ids(map) do
    map
  end
end
