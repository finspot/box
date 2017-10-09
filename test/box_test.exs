defmodule BoxTest do
  use ExUnit.Case
  doctest Box
  doctest Box.TokenCache
  doctest Box.FileName

  # Integration tests
  test "happy path" do
    Box.Mock.mock fn
      {:files, "folder_id"} -> {:ok, []}
      {:upload, "folder_id", "foo - page 1.pdf", "/tmp/foo.pdf"} -> {:ok, "box_id"}
    end

    assert {:ok, "box_id"} = Box.upload("folder_id", "foo.pdf", "/tmp/foo.pdf")
  end

  test "with renaming" do
    Box.Mock.mock fn
      {:files, "folder_id"} -> {:ok, ["foo - page 1.pdf"]}
      {:upload, "folder_id", "foo - page 2.pdf", "/tmp/foo.pdf"} -> {:ok, "box_id"}
    end

    assert {:ok, "box_id"} = Box.upload("folder_id", "foo.pdf", "/tmp/foo.pdf")
  end

  test "invalid folder id" do
    Box.Mock.mock fn
      {:files, "folder_id"} -> {:error, :folder_not_found}
    end

    assert {:error, :folder_not_found} = Box.upload("folder_id", "foo.pdf", "/tmp/foo.pdf")
  end

  test "box is down" do
    Box.Mock.mock fn
      {:files, "folder_id"} -> {:ok, []}
      {:upload, "folder_id", "foo - page 1.pdf", "/tmp/foo.pdf"} -> {:error, :box_error}
    end

    assert {:error, :box_error} = Box.upload("folder_id", "foo.pdf", "/tmp/foo.pdf")
  end
end
