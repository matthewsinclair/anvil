defmodule AnvilWeb.PageController do
  use AnvilWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def dashboard(conn, _params) do
    conn
    |> put_layout(html: {AnvilWeb.Layouts, :dashboard})
    |> assign(:page_title, "Dashboard")
    |> render(:dashboard)
  end

  def account(conn, _params) do
    conn
    |> put_layout(html: {AnvilWeb.Layouts, :dashboard})
    |> assign(:page_title, "Account")
    |> render(:account)
  end

  def settings(conn, _params) do
    conn
    |> put_layout(html: {AnvilWeb.Layouts, :dashboard})
    |> assign(:page_title, "Settings")
    |> render(:settings)
  end

  def help(conn, _params) do
    conn
    |> put_layout(html: {AnvilWeb.Layouts, :dashboard})
    |> assign(:page_title, "Help")
    |> render(:help)
  end
end
