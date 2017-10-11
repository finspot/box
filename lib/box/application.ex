defmodule Box.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @default_port 4000

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Box.Endpoint, [], port: port()),
      Box.TokenCache
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Box.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp port do
    case System.get_env("PORT") do
      nil -> @default_port
      port -> String.to_integer(port)
    end
  end
end
