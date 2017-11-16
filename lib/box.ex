defmodule Box do
  alias Box.Folders
  alias Box.Folder

  require Logger

  @client Application.get_env(:box, :client)

  @doc """
  Helper function for current time
  """
  def get_timestamp do
    :os.system_time(:seconds)
  end

  def upload(folder_id, filename, filepath) do
    Logger.info("Starting upload of #{filename} into folder #{folder_id}")

    with {:ok, new_name} <- folder_id |> Folders.folder() |> Folder.pick_filename(filename),
         {:ok, box_id} <- @client.upload(folder_id, new_name, filepath) do
      {:ok, box_id}
    else
      {:error, :filename_already_taken} ->
        Box.Folders.reset(folder_id)
        upload(folder_id, filename, filepath)

      error ->
        error
    end
  end
end
