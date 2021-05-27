defmodule Shopifex.Plug.ShopifyWebhook do
  import Plug.Conn
  require Logger

  def init(options) do
    # initialize options
    options
  end

  @doc """
  Ensures that the connection has a valid Shopify webhook HMAC token and puts the shop in conn.private
  """
  def call(conn, _) do
    {their_hmac, our_hmac} =
      case conn.method do
        "GET" ->
          {
            conn.params["hmac"],
            Shopify.Hmac.hmac_map(conn.params) |> String.downcase()
          }

        "POST" ->
          case Plug.Conn.get_req_header(conn, "x-shopify-hmac-sha256") do
            [header_hmac] ->
              our_hmac = Shopify.Hmac.hmac_raw_body(conn.assigns[:raw_body])
              {header_hmac, our_hmac}

            [] ->
              conn
              |> send_resp(401, "missing hmac signature")
              |> halt()
          end
      end

    if our_hmac == their_hmac do
      shop =
        case Plug.Conn.get_req_header(conn, "x-shopify-shop-domain") do
          [shop_url] ->
            shop_url

          _ ->
            conn.params["myshopify_domain"] || conn.query_params["shop"]
        end
        |> Shopifex.Shops.get_shop_by_url()

      if shop do
        host = Map.get(conn.params, "host")
        locale = Map.get(conn.params, "locale")
        Shopifex.Plug.ShopifySession.put_shop_in_session(conn, shop, host, locale)
      else
        conn
        |> send_resp(404, "no store found with url")
        |> halt()
      end
    else
      Logger.info("HMAC doesn't match " <> our_hmac)

      conn
      |> send_resp(401, "invalid hmac signature")
      |> halt()
    end
  end
end
