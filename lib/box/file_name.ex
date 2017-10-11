defmodule Box.FileName do
  @page_split " - page "

  @doc """
  Update a file name not to be duplicated, ignoring extensions
  iex> Box.FileName.deduplicate("foo.pdf", [])
  "foo - page 1.pdf"
  iex> Box.FileName.deduplicate("foo.pdf", ["foo.pdf", "bar.pdf"])
  "foo - page 2.pdf"
  iex> Box.FileName.deduplicate("foo.pdf", ["foo - page 1.pdf", "foo - page 3.exe"])
  "foo - page 4.pdf"
  """
  def deduplicate(filename, list) do
    {basename, _nb, ext} = split_file(filename)

    next_page_number =
      list
      |> Enum.map(&split_file/1)
      |> Enum.filter(fn {name, _nb, _ext} -> name == basename end)
      |> Enum.map(fn {_name, nb, _ext} -> nb end)
      |> next_number()

    basename <> @page_split <> "#{next_page_number}" <> ext
  end

  @doc """
  Finds the next available number in a list, assuming nils are 1

  iex> Box.FileName.next_number([])
  1
  iex> Box.FileName.next_number([nil, nil])
  2
  iex> Box.FileName.next_number([nil, 4, 1])
  5
  """
  def next_number([]), do: 1

  def next_number(files) do
    files
    |> Enum.map(fn
         nb when is_number(nb) -> nb + 1
         _ -> 2
       end)
    |> Enum.max()
  end

  @doc """
  Split a file into 3 components :
  - base name
  - page number
  - extension

  iex> Box.FileName.split_file("foo - page 4.pdf")
  {"foo", 4, ".pdf"}
  iex> Box.FileName.split_file("bar.jpeg")
  {"bar", nil, ".jpeg"}
  """
  def split_file(filename) do
    extname = Path.extname(filename)
    basename = Path.basename(filename, extname)

    with [name, page] <- String.split(basename, @page_split),
         {number, _rest} <- Integer.parse(page) do
      {name, number, extname}
    else
      _ -> {basename, nil, extname}
    end
  end
end
