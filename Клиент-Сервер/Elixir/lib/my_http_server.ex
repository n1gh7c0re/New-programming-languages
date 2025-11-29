defmodule MyHttpServer do
  use Plug.Router
  require Logger

  plug :match
  plug :dispatch

  def start_link do
    {:ok, config_data} = File.read("server_config.json")
    config = Jason.decode!(config_data)
    port = config["port"]
    greeting = config["greeting"]

    {:ok, _} = Plug.Cowboy.http(__MODULE__, [], port: port)
    Logger.info("Server started on port #{port} with greeting: #{greeting}")
    {:ok, self()}
  end

  get "/ping" do
    send_resp(conn, 200, Jason.encode!(%{"status" => "ok"}))
  end

  post "/echo" do
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    time_ms = :os.system_time(:millisecond)

    log_entry = %{
      method: conn.method,
      path: conn.request_path,
      body: body,
      time_ms: time_ms
    }
    File.write!("requests.log", Jason.encode!(log_entry) <> "\n", [:append])

    send_resp(conn, 200, Jason.encode!(%{"saved" => true}))
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end