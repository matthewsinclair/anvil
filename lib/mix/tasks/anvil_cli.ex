defmodule Mix.Tasks.Anvil.Cli do
  @moduledoc "Custom mix tasks for Anvil CLI: mix anvil.cli"
  use Mix.Task
  alias Arca.Cli, as: Cli

  @impl Mix.Task
  @requirements ["app.config", "app.start"]
  @shortdoc "Runs the Anvil CLI"
  @doc "Invokes the Anvil CLI and passes it the supplied command line params."
  def run(args) do
    Cli.main(args)
  end
end
