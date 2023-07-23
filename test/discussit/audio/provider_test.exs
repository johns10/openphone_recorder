defmodule Discussit.Audio.ProviderTest do
  use ExUnit.Case
  doctest Discussit.Audio.Provider
  alias Discussit.Audio.Provider

  describe "Audio" do
    @tag :integration
    test "splits correctly" do
      {:ok, %{left: left, right: right}} =
        "./test/support/fixtures/2channel.mp3"
        |> Path.expand()
        |> Provider.split()

      assert File.exists?(left)
      assert File.exists?(right)
    end

    @tag :integration
    test "errors correctly" do
      assert {:error, _} =
               "asdf"
               |> Path.expand()
               |> Provider.split()
    end
  end
end
