# Folder filenames cache, allowing parallel uploads with
# incrementing indices without hitting the API too hard
defmodule Box.Folder do
  alias Box.FileName
  use GenServer

  @client Application.get_env(:box, :client)

  # 1 hour
  @cache_ttl 3600

  def start_link(folder_id, opts \\ []) do
    GenServer.start_link(__MODULE__, folder_id, opts)
  end

  def init(folder_id) do
    initial_state = %{
      folder_id: folder_id,
      last_update: nil,
      files: []
    }

    {:ok, initial_state}
  end

  def pick_filename(pid, filename) do
    GenServer.call(pid, {:pick_filename, filename})
  end

  def handle_call({:pick_filename, filename}, _from, state) do
    case update_cache(state) do
      {:error, err} ->
        {:reply, {:error, err}, state}

      {:ok, state} ->
        {new_state, new_filename} = choose_and_cache_filename(state, filename)
        {:reply, {:ok, new_filename}, new_state}
    end
  end

  defp choose_and_cache_filename(state = %{files: files}, filename) do
    new_filename = FileName.deduplicate(filename, files)
    {%{state | files: [new_filename | files]}, new_filename}
  end

  defp update_cache(state) do
    case should_update_cache?(state) do
      false ->
        {:ok, state}

      true ->
        case @client.files(state.folder_id) do
          {:ok, files} -> {:ok, %{state | last_update: :os.system_time(:seconds), files: files}}
          {:error, err} -> {:error, err}
        end
    end
  end

  defp should_update_cache?(%{last_update: nil}), do: true

  defp should_update_cache?(%{last_update: time}) do
    now = :os.system_time(:seconds)
    time + @cache_ttl < now
  end
end
