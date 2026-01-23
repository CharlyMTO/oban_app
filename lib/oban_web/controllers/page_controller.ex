defmodule ObanWeb.PageController do
  use ObanWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
