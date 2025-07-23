defmodule Anvil.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AnvilWeb.Telemetry,
      Anvil.Repo,
      {DNSCluster, query: Application.get_env(:anvil, :dns_cluster_query) || :ignore},
      {Oban,
       AshOban.config(
         Application.fetch_env!(:anvil, :ash_domains),
         Application.fetch_env!(:anvil, Oban)
       )},
      {Phoenix.PubSub, name: Anvil.PubSub},
      # Start a worker by calling: Anvil.Worker.start_link(arg)
      # {Anvil.Worker, arg},
      # Start to serve requests, typically the last entry
      AnvilWeb.Endpoint,
      {Absinthe.Subscription, AnvilWeb.Endpoint},
      AshGraphql.Subscription.Batcher,
      {AshAuthentication.Supervisor, [otp_app: :anvil]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Anvil.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AnvilWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
