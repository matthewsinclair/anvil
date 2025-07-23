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
      # Start the cache for prompts
      {Anvil.Cache, subscribe_to_updates: true},
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

  @impl true
  def start_phase(:validate_directories, _type, _args) do
    # Validate required directories exist
    :ok
  end

  @impl true
  def start_phase(:load_schemas, _type, _args) do
    # Load any required schemas
    :ok
  end

  @impl true
  def start_phase(:initialize_registries, _type, _args) do
    # Initialize any required registries
    :ok
  end

  @impl true
  def start_phase(:register_config_callbacks, _type, _args) do
    # Register configuration callbacks
    :ok
  end

  @impl true
  def start_phase(:load_config, _type, _args) do
    # Load configuration from dependencies in deterministic order
    with :ok <- Arca.Config.load_config_phase(),
         :ok <- Arca.Cli.load_config_phase() do
      :ok
    end
  end
end
