defmodule ShopifexWeb.DashboardController do
  use ShopifexWeb, :controller

  def index(conn, _params) do
    conn
    |> render("index.html")
  end
end
