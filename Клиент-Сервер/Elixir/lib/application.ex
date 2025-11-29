defmodule MyHttpServer.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {MyHttpServer, []}
    ]

    opts = [strategy: :one_for_one, name: MyHttpServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end