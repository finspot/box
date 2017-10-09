# Stolen mock implementation from tesla: https://github.com/teamon/tesla/blob/master/lib/tesla/mock.ex
defmodule Box.Mock do
  def mock(fun) when is_function(fun) do
    Process.put(__MODULE__, fun)
  end

  def files(folder_id) do
    do_call({:files, folder_id})
  end

  def upload(folder_id, filename, filepath) do
    do_call({:upload, folder_id, filename, filepath})
  end

  defp do_call(args) do
    case Process.get(__MODULE__) do
      nil -> raise "Box Mock is not configured"
      fun -> fun.(args)
    end
  end
end
