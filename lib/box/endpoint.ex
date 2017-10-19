defmodule Box.Endpoint do
  use Plug.Router
  use Plug.ErrorHandler
  require Logger

  # 50 MB max size
  @max_length 51 * 1024 * 1024

  plug(Plug.Logger)
  plug(Plug.Parsers, parsers: [:urlencoded, :multipart], length: @max_length)
  plug(:handle_cors)
  plug(:match)
  plug(:dispatch)

  post "/upload/:folder_id/:sig" do
    with :ok <- validate_signature(folder_id, sig),
         {:ok, file} <- get_file_from_params(conn),
         {:ok, box_id} <- Box.upload(folder_id, file.filename, file.path) do
      send_resp(conn, 201, box_id)
    else
      {:error, :invalid_signature} -> send_resp(conn, 401, "Invalid signature")
      {:error, :no_file} -> send_resp(conn, 400, "No file in params")
      {:error, :box_error} -> send_resp(conn, 502, "Box.com did not respond")
      {:error, :folder_not_found} -> send_resp(conn, 404, "No folder found")
      err -> handle_errors(conn, err)
    end
  end

  # OPTIONS
  options "/upload/:folder_id/:sig" do
    send_resp(conn, 200, "")
  end

  # Default 404
  match _ do
    send_resp(conn, 404, "")
  end

  # Generic error handler for plug
  def handle_errors(conn, err) do
    Logger.error(["An error happened", inspect(err, pretty: true)])
    send_resp(conn, 500, "An error happened")
  end

  # CORS
  defp handle_cors(conn, _) do
    conn
    |> put_resp_header("Access-Control-Allow-Origin", "*")
  end

  defp validate_signature(folder_id, sig) do
    case Box.Signature.verify(folder_id, sig) do
      true -> :ok
      false -> {:error, :invalid_signature}
    end
  end

  defp get_file_from_params(conn) do
    case conn.params do
      %{"file" => file = %Plug.Upload{}} -> {:ok, file}
      _ -> {:error, :no_file}
    end
  end
end
