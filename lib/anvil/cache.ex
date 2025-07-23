defmodule Anvil.Cache do
  @moduledoc """
  ETS-based cache for prompt storage with PubSub invalidation.
  """

  use GenServer
  require Logger

  @table_name :anvil_prompt_cache
  @default_ttl :timer.minutes(5)

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec get(map()) :: {:ok, map()} | :miss
  def get(address_map) do
    key = cache_key(address_map)

    case :ets.lookup(@table_name, key) do
      [{^key, prompt, expiry}] ->
        if DateTime.compare(expiry, DateTime.utc_now()) == :gt do
          {:ok, prompt}
        else
          :ets.delete(@table_name, key)
          :miss
        end

      [] ->
        :miss
    end
  end

  @spec put(map(), map()) :: :ok
  def put(address_map, prompt) do
    key = cache_key(address_map)
    expiry = DateTime.add(DateTime.utc_now(), @default_ttl, :millisecond)

    :ets.insert(@table_name, {key, prompt, expiry})
    :ok
  end

  @spec invalidate(String.t()) :: :ok
  def invalidate(prompt_set_id) do
    GenServer.cast(__MODULE__, {:invalidate, prompt_set_id})
  end

  @spec clear() :: :ok
  def clear do
    GenServer.cast(__MODULE__, :clear)
  end

  # Server callbacks

  @impl true
  def init(opts) do
    :ets.new(@table_name, [:named_table, :public, read_concurrency: true])

    # Subscribe to prompt updates if configured
    if opts[:subscribe_to_updates] do
      Phoenix.PubSub.subscribe(Anvil.PubSub, "prompts:updates")
    end

    {:ok, %{}}
  end

  @impl true
  def handle_cast({:invalidate, prompt_set_id}, state) do
    # Delete all entries matching the prompt set
    :ets.match_delete(@table_name, {{:_, prompt_set_id, :_, :_}, :_, :_})
    Logger.info("Cache invalidated for prompt set: #{prompt_set_id}")

    {:noreply, state}
  end

  @impl true
  def handle_cast(:clear, state) do
    :ets.delete_all_objects(@table_name)
    Logger.info("Cache cleared")

    {:noreply, state}
  end

  @impl true
  def handle_info({:prompt_updated, prompt_set_id, _prompt}, state) do
    invalidate(prompt_set_id)
    {:noreply, state}
  end

  # Private functions

  defp cache_key(%{repository: repo, bundle: bundle, version: version, prompt_name: name}) do
    {repo, bundle, version, name}
  end
end
