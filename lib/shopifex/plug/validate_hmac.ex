defmodule Shopifex.Plug.ValidateHmac do
  import Plug.Conn

  def init(options) do
    # initialize options
    options
  end

  def call(conn = %{params: %{"hmac" => hmac}}, _) do
    if Shopify.Hmac.valid_conn?(conn) do
      conn
    else
      respond_invalid(conn)
    end
  end

  defp respond_invalid(conn) do
    conn
    |> resp(:forbidden, "No valid HMAC")
    |> send_resp()
    |> halt()
  end
end
