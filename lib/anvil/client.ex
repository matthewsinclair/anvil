defmodule Anvil.Client do
  @moduledoc """
  Client library for consuming Anvil prompts in applications.
  """

  alias Anvil.{Cache, Registry, Resolver, Template}

  @doc """
  Get a prompt by its address, with parameter interpolation.

  ## Examples

      iex> Anvil.Client.get("@local/onboarding@stable/welcome", 
      ...>   user_name: "Alice", 
      ...>   product: "Anvil")
      {:ok, "Welcome to Anvil, Alice!"}
      
      iex> Anvil.Client.get("@anvil/core@2.1.0/error_message",
      ...>   error: "Not found")
      {:ok, "Sorry, we couldn't find what you're looking for: Not found"}
  """
  @spec get(String.t(), keyword() | map()) :: {:ok, String.t()} | {:error, term()}
  def get(address, params \\ %{}) do
    with {:ok, parsed} <- Resolver.parse_address(address),
         {:ok, prompt} <- fetch_prompt(parsed),
         {:ok, rendered} <- Template.render(prompt.template, params) do
      {:ok, rendered}
    end
  end

  @doc """
  Get a prompt, raising on error.
  """
  @spec get!(String.t(), keyword() | map()) :: String.t()
  def get!(address, params \\ %{}) do
    case get(address, params) do
      {:ok, prompt} -> prompt
      {:error, reason} -> raise Anvil.Error, reason: reason
    end
  end

  defp fetch_prompt(parsed_address) do
    case Cache.get(parsed_address) do
      {:ok, prompt} ->
        {:ok, prompt}

      :miss ->
        with {:ok, prompt} <- Registry.fetch(parsed_address) do
          Cache.put(parsed_address, prompt)
          {:ok, prompt}
        end
    end
  end
end
