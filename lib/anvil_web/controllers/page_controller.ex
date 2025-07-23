defmodule AnvilWeb.PageController do
  use AnvilWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def dashboard(conn, _params) do
    render(conn, :dashboard)
  end

  def account(conn, _params) do
    render(conn, :account)
  end

  def settings(conn, _params) do
    render(conn, :settings)
  end

  def help(conn, _params) do
    render(conn, :help)
  end
end
