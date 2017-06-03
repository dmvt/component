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
    Logger.log(level, conn_to_log(conn, :call))
    conn
  end

  @doc false
  def respond(conn, level) do
    Logger.log(level, conn_to_log(conn, :respond))
    conn
  end

  # private

  defp conn_to_log(conn, function_name) do
    ["Component.Logger.#{function_name} at ",
     to_string(DateTime.utc_now),
     ": ",
     inspect(conn)]
  end
end
