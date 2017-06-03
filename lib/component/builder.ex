defmodule Component.Builder do
  @moduledoc """
  Conveniences for building components.

  This module can be `use`-d into a module in order to build a component
  pipeline:

      defmodule MyApp do
        use Component.Builder

        component Component.Logger, some: :option
        component :a_component_function
        component SomethingElse
      end

  Multiple components can be defined with the `component/2` macro, forming a
  pipeline. The components in the pipeline will be executed in the order
  they've been added through the `component/2` macro.

  ## Component behaviour

  Internally, `Component.Builder` implements the `Component` behaviour, which
  means both the `call/2` and `respond/2` functions are defined.

  In the example above,
  calling `MyApp.call/2` will in turn call the following functions in order:

  - `Component.Logger.call/2`
  - `a_component_function/2`
  - `SomethingElse.call/2`
  - `SomethingElse.respond/2`
  - `Component.Logger.respond/2`
  - `MyApp.respond/2`

  `respond/2` can be overriden if there is something you'd like to do with the
  final conn object before returning it. This should be avoided in favor of a
  component module which implements the `respond/2` function.
  """

  @type component :: module

  @doc false
  defmacro __using__(opts) do
    quote do
      use Component

      @component_builder_opts unquote(opts)

      def call(conn, opts), do: component_builder_call(conn, opts)

      defoverridable [call: 2]

      import Component.Builder, only: [component: 1, component: 2]

      Module.register_attribute(__MODULE__, :components, accumulate: true)
      @before_compile Component.Builder
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    components = Module.get_attribute(env.module, :components)
    builder_opts = Module.get_attribute(env.module, :component_builder_opts)

    {conn, body} = Component.Builder.compile(env, components, builder_opts)

    quote do
      defp component_builder_call(unquote(conn), _opts), do: unquote(body)
    end
  end

  @doc """
  A macro that stores a new component. `opts` will be passed unchanged to the
  component's `call/2` and `respond/2` functions.
  """
  defmacro component(component, opts \\ [])
  defmacro component(component, opts) do
    quote do
      @components {unquote(component), unquote(opts), true}
    end
  end

  @doc """
  Compiles a component pipeline.

  Each element of the component pipeline (according to the type signature of
  this function) has the form:

      {component_name, options, guards}

  Note that this function expects a reversed pipeline (with the last component that
  has to be called coming first in the pipeline).

  The function returns a tuple with the first element being a quoted reference
  to the connection and the second element being the compiled quoted pipeline.

  ## Examples

      Component.Builder.compile(env, [
        {Component.Logger, [], true}, # no guards
        {GuardedComponent, [], quote(do: a when is_binary(a))}
      ], [])

  """
  @spec compile(
    Macro.Env.t,
    [{component, Component.opts, Macro.t}],
    Keyword.t
  ) :: {Macro.t, Macro.t}
  def compile(env, pipeline, builder_opts) do
    conn = quote do: conn

    pipeline = Enum.map(pipeline, &init_component(&1))

    compiled_pipeline = Enum.reduce(
      Enum.reverse(pipeline),
      conn,
      &quote_component_calls(&1, &2, env, builder_opts)
    )

    compiled_pipeline = Enum.reduce(
      pipeline,
      compiled_pipeline,
      &quote_component_responds(&1, &2, env, builder_opts)
    )

    {conn, compiled_pipeline}
  end

  # private

  defp compile_guards(call, true) do
    call
  end

  defp compile_guards(call, guards) do
    quote do
      case true do
        true when unquote(guards) -> unquote(call)
        true -> conn
      end
    end
  end

  # Initializes the options of a component at compile time.
  defp init_component({component, opts, guards}) do
    case Atom.to_charlist(component) do
      ~c"Elixir." ++ _ ->
        init_module_component(component, opts, guards)
      _ ->
        init_fun_component(component, opts, guards)
    end
  end

  defp init_fun_component(component, opts, guards) do
    {:function, component, opts, guards}
  end

  defp init_module_component(component, opts, guards) do
    initialized_opts = component.init(opts)

    Enum.each([:call, :respond], fn(fun) ->
      if !function_exported?(component, fun, 2) do
        raise ArgumentError,
          message: "#{inspect component} component must implement #{fun}/2"
      end
    end)

    {:module, component, initialized_opts, guards}
  end

  defp quote_component_call(:function, component, opts) do
    quote do: unquote(component)(conn, unquote(Macro.escape(opts)))
  end

  defp quote_component_call(:module, component, opts) do
    quote do: unquote(component).call(conn, unquote(Macro.escape(opts)))
  end

  defp quote_component_calls(
    {component_type, component, opts, guards},
    acc,
    _env,
    _builder_opts
  ) do
    call = quote_component_call(component_type, component, opts)
    wrap_existing_ast(call, guards, acc)
  end

  defp quote_component_responds(
    {:function, _component, _opts, _guards},
    acc,
    _env,
    _builder_opts
  ) do
    acc
  end

  defp quote_component_responds(
    {:module, component, opts, guards},
    acc,
    _env,
    _builder_opts
  ) do
    call =
      quote do
        unquote(component).respond(conn, unquote(Macro.escape(opts)))
      end

    wrap_existing_ast(call, guards, acc)
  end

  defp wrap_existing_ast(call, guards, acc) do
    {fun, meta, [_arg1, opts]} = quote do: unquote(compile_guards(call, guards))
    {fun, [generated: true] ++ meta, [acc, opts]}
  end
end
