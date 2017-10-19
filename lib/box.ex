defmodule Box do
  alias Box.FileName
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

    with {:ok, folder_contents} <- @client.files(folder_id),
         new_name <- FileName.deduplicate(filename, folder_contents),
         {:ok, box_id} <- @client.upload(folder_id, new_name, filepath) do
      {:ok, box_id}
    else
      # Retry
      {:error, :filename_already_taken} ->
        upload(folder_id, filename, filepath)

      error ->
        error
    end
  end
end
