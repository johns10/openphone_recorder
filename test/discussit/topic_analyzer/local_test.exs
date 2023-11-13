defmodule Discussit.TopicAnalyzer.LocalTest do
  use ExUnit.Case
  alias Discussit.TopicAnalyzer.Local

  describe "Local Python Server" do
    @tag :integration
    test "starting and works" do
      {:ok, pid} = Local.start()
      assert is_pid(pid)
      assert :ok = Local.stop(pid)
    end

    @tag :integration
    test "starting the server works" do
      {:ok, pid} = Local.start()
      assert {:ok, %{port: _, status: :started}} = Local.start_server(pid)
      assert {:ok, pid} = Local.stop_server(pid)
      assert :ok = Local.stop(pid)
    end
  end
end
