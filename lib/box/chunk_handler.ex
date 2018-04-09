defmodule Box.ChunkHandler do
  @moduledoc """
  Stateless chunk handling and merging yay!
  """
  @tmpdir "/tmp"
  @outfile "out"

  # Public API
  def has_chunk?(file_id, chunk_nb) do
    local_path(file_id, chunk_nb) |> File.exists?()
  end

  def handle_chunk(file_id, chunk_nb, path, total_chunks) do
    folder = folder(file_id)
    :ok = File.mkdir_p(folder)

    dest = local_path(file_id, chunk_nb)
    :ok = File.cp(path, dest)

    case current_chunk_count(file_id) do
      ^total_chunks -> {:finished, compact_chunks!(file_id)}
      count -> {:in_progress, count / total_chunks}
    end
  end

  def folder(file_id) do
    "#{@tmpdir}/chunks/#{file_id}"
  end

  def local_path(file_id, chunk_nb) do
    folder(file_id) <> "/" <> lex_index(chunk_nb) <> ".chunk"
  end

  def current_chunk_count(file_id) do
    {:ok, files} = File.ls(folder(file_id))
    length(files)
  end

  def compact_chunks!(file_id) do
    folder = folder(file_id)
    outfile = folder <> "/" <> @outfile
    file = File.stream!(outfile)

    # Compact into out file
    Path.wildcard("#{folder}/*.chunk")
    |> Stream.map(&File.read!/1)
    |> Stream.into(file)
    |> Stream.run()

    # Remove chunks
    Path.wildcard("#{folder}/*.chunk")
    |> Enum.each(&File.rm!/1)

    outfile
  end

  @doc """
  Lexicographically ordered index for a number (done via packing by nb of digits)
  iex> Box.ChunkHandler.lex_index(1)
  "a 1"
  iex> Box.ChunkHandler.lex_index(2)
  "a 2"
  iex> Box.ChunkHandler.lex_index(11)
  "b 11"
  """
  def lex_index(nb) do
    bin = [96 + length(Integer.digits(nb))]
    "#{bin} #{nb}"
  end
end
