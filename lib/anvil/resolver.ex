defmodule Anvil.Resolver do
  @moduledoc """
  Resolves prompt addresses to specific versions.
  """

  @address_regex ~r/^@([^\/]+)\/([^@]+)@([^\/]+)\/(.+)$/

  @spec parse_address(String.t()) :: {:ok, map()} | {:error, :invalid_address_format}
  def parse_address(address) do
    case Regex.run(@address_regex, address) do
      [_, repo, bundle, version, prompt_name] ->
        {:ok,
         %{
           repository: repo,
           bundle: bundle,
           version: version,
           prompt_name: prompt_name
         }}

      _ ->
        {:error, :invalid_address_format}
    end
  end

  @spec resolve_version(String.t(), String.t()) :: {:ok, String.t()} | {:error, term()}
  def resolve_version(bundle, version_spec) do
    cond do
      version_spec == "stable" ->
        get_stable_version(bundle)

      version_spec == "latest" ->
        get_latest_version(bundle)

      String.starts_with?(version_spec, "^") ->
        resolve_caret_version(bundle, version_spec)

      true ->
        get_exact_version(bundle, version_spec)
    end
  end

  defp get_stable_version(_bundle) do
    # TODO: Implement stable version lookup
    {:ok, "1.0.0"}
  end

  defp get_latest_version(_bundle) do
    # TODO: Implement latest version lookup
    {:ok, "1.0.0"}
  end

  defp resolve_caret_version(_bundle, _version_spec) do
    # TODO: Implement caret version resolution
    {:ok, "1.0.0"}
  end

  defp get_exact_version(_bundle, version) do
    {:ok, version}
  end
end
