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

    @tag :integration
    test "removes m4a correctly" do
      output = Path.expand("./test/support/fixtures/temp_audio.m4a")

      assert {:ok, output} ==
               "./test/support/fixtures/short_video.mp4"
               |> Path.expand()
               |> Provider.mp4_to_m4a(output)

      File.rm!(output)
    end

    @tag :integration
    test "mp4_to_m4a errors correctly" do
      assert {:error, _} =
               "asdf"
               |> Path.expand()
               |> Provider.split()
    end
  end
end
