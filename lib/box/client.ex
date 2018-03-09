defmodule Box.Client do
  use Tesla

  alias Tesla.Multipart

  plug(Tesla.Middleware.BaseUrl, "https://api.box.com/2.0")
  plug(Box.OAuth2)
  plug(Tesla.Middleware.JSON)

  adapter(Tesla.Adapter.Hackney)

  def files(folder_id) do
    case get("/folders/#{folder_id}/items") do
      %{status: 200, body: body} -> {:ok, extract_files(body)}
      %{status: 404} -> {:error, :folder_not_found}
      _ -> {:error, :box_error}
    end
  end

  def upload(folder_id, filename, filepath) do
    # Build request body
    attributes = %{name: filename, parent: %{id: folder_id}}

    mp =
      Multipart.new()
      |> Multipart.add_content_type_param("charset=utf-8")
      |> Multipart.add_field("attributes", Poison.encode!(attributes))
      |> Multipart.add_file(filepath)

    case post("https://upload.box.com/api/2.0/files/content", mp) do
      %{status: 201, body: %{"entries" => [%{"id" => box_id}]}} -> {:ok, box_id}
      %{status: 409} -> {:error, :filename_already_taken}
      _ -> {:error, :box_error}
    end
  end

  defp extract_files(%{"entries" => entries}) do
    entries
    |> Enum.map(fn %{"name" => name} -> name end)
  end
end
