defmodule Box do
  alias Box.Client
  alias Box.FileName

  @doc """
  Helper function for current time
  """
  def get_timestamp do
    :os.system_time(:seconds)
  end

  def upload(folder_id, filename, filepath) do
    with {:ok, folder_contents} = Client.files(folder_id),
         new_name <- FileName.deduplicate(filename, folder_contents),
         {:ok, box_id} <- Client.upload(folder_id, new_name, filepath) do
      {:ok, box_id}
    end
  end

end
