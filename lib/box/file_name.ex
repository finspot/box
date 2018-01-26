defmodule Box.FileName do
  @windows_reserved_chars ["<", ">", ":", "\"", "/", "\\", "|", "?", "*"]

  @doc """
  Update a file name not to be duplicated, ignoring extensions
  iex> Box.FileName.deduplicate("foo.pdf", [])
  "foo.pdf"
  iex> Box.FileName.deduplicate("foo.pdf", ["foo.pdf", "bar.pdf"])
  "foo (1).pdf"
  iex> Box.FileName.deduplicate("foo.pdf", ["foo (1).pdf", "foo (3).exe"])
  "foo (4).pdf"
  """
  def deduplicate(filename, list) do
    {basename, _nb, ext} = filename |> sanitize |> split_file

    next_page_number =
      list
      |> Enum.map(&split_file/1)
      |> Enum.filter(fn {name, _nb, _ext} -> name == basename end)
      |> Enum.map(fn {_name, nb, _ext} -> nb end)
      |> next_number()

    case next_page_number do
      nil -> basename <> ext
      i -> basename <> " (#{i})" <> ext
    end
  end

  @doc """
  Finds the next available number in a list

  iex> Box.FileName.next_number([])
  nil
  iex> Box.FileName.next_number([nil, nil])
  1
  iex> Box.FileName.next_number([nil, 4, 1])
  5
  """
  def next_number([]), do: nil

  def next_number(files) do
    files
    |> Enum.map(fn
      nb when is_number(nb) -> nb + 1
      _ -> 1
    end)
    |> Enum.max()
  end

  @doc """
  Split a file into 3 components :
  - base name
  - page number
  - extension

  iex> Box.FileName.split_file("foo (4).pdf")
  {"foo", 4, ".pdf"}
  iex> Box.FileName.split_file("bar.jpeg")
  {"bar", nil, ".jpeg"}
  """
  def split_file(filename) do
    extname = Path.extname(filename)
    basename = Path.basename(filename, extname)

    with [_, name, page] <- Regex.run(~r/^(.*) \((\d+)\)$/, basename),
         {number, _rest} <- Integer.parse(page) do
      {name, number, extname}
    else
      _ -> {basename, nil, extname}
    end
  end

  @doc """
  Sanitize a filename to handle windows filesystem
  iex> Box.FileName.sanitize("Relevé : 1.jpeg")
  "Relevé - 1.jpeg"
  """
  def sanitize(filename) do
    String.replace(filename, @windows_reserved_chars, "-")
  end
end
