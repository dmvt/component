# Component

Component is a specification for composable modules between applications. It is
heavily inspired by [Plug](https://github.com/elixir-lang/plug). I wanted the
same type of functionality without being locked into the Plug.Conn struct.

## Hello world

```elixir
defmodule MyComponent do
  use Component

  def call(conn, _opts) do
    Map.put(conn, :response, "Hello World!")
  end
end
```

## Installation

You can use component in your projects in one easy step, add component to your
`mix.exs` dependencies:

```elixir
def deps do
  [{:component, "~> 0.1"}]
end
```

## The Resource.conn

In the hello world example, we defined our first component. What is a component?

A component takes two shapes. A function component receives a connection and a
set of options as arguments and returns a connection of the same type:

```elixir
def hello_world_plug(conn, _opts) do
  Map.put(conn, :response, "Hello World!")
end
```

A connection, or conn, should typically be a map or struct, but can also be a
list, tuple or string. The important thing to keep in mind is that conn should
always be of the same type in your application to avoid confusion.

A module component implements an `init/1` function to initialize the options, a `call/2` function which receives the connection and initialized options, and a
`respond/2` function which also receives the connection:

```elixir
defmodule MyComponent do
  @behaviour Component

  def init(opts \\ []), do: opts
  def call(conn, _opts), do: conn
  def respond(conn, _opts), do: conn
end
```

All three of these methods have defaults that are provided if your component
module `use`-s Component.

```elixir
defmodule MyComponent do
  use Component
end
```

If you do decide to `use Component`, be aware that `opts` must be a list. If you
want to pass non-list options, you should instead implement your own module that
conforms to the `Component` behaviour.

### Available Components

This project aims to ship with different plugs that can be re-used across applications:

  * `Component.Logger` - logs conn objects coming in and going out

## Contributing

We welcome everyone to contribute to Component and help us tackle any issues!
Just open a pull request...
