defmodule Component.Logger do
  @moduledoc """
  A component for logging `conn` before and after a pipeline execution:

  To use it, just component it into the desired module.

      component Component.Logger, log: :debug

  ## Options

    * `:log` - The log level used
      Default is `:debug`.
  """

  require Logger
  use Component

  @doc false
  def init(opts) do
    if List.keymember?(opts, :log, 0) do
      opts |> List.keytake(:log, 0) |> elem(0) |> elem(1)
    else
      :debug
    end
  end

  @doc false
  def call(conn, level) do
    Logger.log(level, conn_to_log(conn))
    conn
  end

  @doc false
  def respond(conn, opts), do: call(conn, opts)

  # private

  defp conn_to_log(conn) do
    [DateTime.utc_now, ":", ?\s, inspect(conn)]
  end
end
