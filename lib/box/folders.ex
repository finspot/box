# (basic) registry and dynamic supervisor
defmodule Box.Folders do
  use Supervisor

  @name __MODULE__

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: @name)
  end

  def init(_arg) do
    child_spec = Supervisor.child_spec(Box.Folder, start: {Box.Folder, :start_link, []})
    Supervisor.init([child_spec], strategy: :simple_one_for_one)
  end

  def folder(id) do
    case start_folder(id) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
      e -> throw(e)
    end
  end

  def reset(id) do
    case Process.whereis(name(id)) do
      nil ->
        :ok

      pid ->
        GenServer.stop(pid)
        :ok
    end
  end

  defp start_folder(id) do
    Supervisor.start_child(@name, [id, [name: name(id)]])
  end

  defp name(id) do
    :"folder_#{id}"
  end
end
