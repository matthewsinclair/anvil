defmodule AnvilWeb.PageController do
  use AnvilWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
