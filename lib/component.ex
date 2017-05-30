defmodule Component do
  @moduledoc """
  The Component behaviour specification.

  This is heavily inspired by plug. I wanted the same type of functionality
  without being locked into the Plug.Conn struct.

  #### Function components

  A function component is any function that receives a conn and a set of
  options and returns a conn. Its type signature must be:
      (Component.conn, Component.opts) :: Component.conn

  #### Module components

  Module components function a little bit differently then Module plugs. They
  have two functions, `call/2` and `respond/2`. `call/2` functions are designed
  to be executed in the order they are defined in a pipeline. `respond/2`
  functions are executed in reverse order after all `call/2` functions have been
  executed. `respond/2` can be thought of as similar to the
  [Plug.Conn#register_before_send/2](https://hexdocs.pm/plug/Plug.Conn.html#register_before_send/2)
  function.

  A module component must export:
  - a `call/2` function with the signature above
  - an `init/1` function which takes a set of options and initializes it
  - a `respond/2` function with the signature above

  Conn should always be of the same type going out as it is coming in. While it
  is possible to not follow this pattern, failure to do so will likely make this
  all super confusing.
  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Component

      def call(conn, opts \\ [])
      def call(conn, opts) when is_list(opts), do: conn
      def call(_conn, _opts) do
        raise ArgumentError, message: "opts must be a list"
      end

      def init(opts \\ [])
      def init(opts) when is_list(opts), do: opts
      def init(_opts) do
        raise ArgumentError, message: "opts must be a list"
      end

      def respond(conn, opts \\ [])
      def respond(conn, opts) when is_list(opts), do: conn
      def respond(_conn, _opts) do
        raise ArgumentError, message: "opts must be a list"
      end

      defoverridable [call: 2, init: 1, respond: 2]
    end
  end

  @type conn :: binary | tuple | list | map | struct
  @type opts :: [{atom, any}]

  @doc """
  Called at the top of the stack.
  """
  @callback call(conn, opts) :: conn | {:halt, conn}

  @doc """
  Called at the bottom of the stack.
  """
  @callback respond(conn, opts) :: conn
end
