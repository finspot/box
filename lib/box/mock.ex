# Stolen mock implementation from tesla: https://github.com/teamon/tesla/blob/master/lib/tesla/mock.ex
defmodule Box.Mock do
  def start_link do
    Agent.start_link(fn -> nil end, name: __MODULE__)
  end

  def mock(fun) when is_function(fun) do
    Agent.update(__MODULE__, fn _ -> fun end)
  end

  def files(folder_id) do
    do_call({:files, folder_id})
  end

  def upload(folder_id, filename, filepath) do
    do_call({:upload, folder_id, filename, filepath})
  end

  defp do_call(args) do
    case Agent.get(__MODULE__, & &1) do
      nil -> raise "Box Mock is not configured"
      fun -> fun.(args)
    end
  end
end
