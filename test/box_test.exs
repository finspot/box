defmodule BoxTest do
  use ExUnit.Case
  doctest Box
  doctest Box.TokenCache
  doctest Box.FileName

  setup_all do
    {:ok, _} = Box.Mock.start_link()
    :ok
  end

  # Integration tests
  test "happy path with renaming" do
    Box.Mock.mock(fn
      {:files, "folder_id"} -> {:ok, []}
      {:upload, "folder_id", "foo - page 1.pdf", "/tmp/foo.pdf"} -> {:ok, "box_id_1"}
      {:upload, "folder_id", "foo - page 2.pdf", "/tmp/foo.pdf"} -> {:ok, "box_id_2"}
    end)

    assert {:ok, "box_id_1"} = Box.upload("folder_id", "foo.pdf", "/tmp/foo.pdf")
    assert {:ok, "box_id_2"} = Box.upload("folder_id", "foo.pdf", "/tmp/foo.pdf")
  end

  test "invalid folder id" do
    Box.Mock.mock(fn {:files, "invalid_folder_id"} -> {:error, :folder_not_found} end)

    assert {:error, :folder_not_found} =
             Box.upload("invalid_folder_id", "foo.pdf", "/tmp/foo.pdf")
  end

  test "box is down" do
    Box.Mock.mock(fn
      {:files, "down_folder_id"} -> {:ok, []}
      {:upload, "down_folder_id", "foo - page 1.pdf", "/tmp/foo.pdf"} -> {:error, :box_error}
    end)

    assert {:error, :box_error} = Box.upload("down_folder_id", "foo.pdf", "/tmp/foo.pdf")
  end
end
