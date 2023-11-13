defmodule Discussit.TopicAnalyzer.ServerTest do
  use ExUnit.Case
  alias Discussit.TopicAnalyzer.Server

  describe "Topic Analyzer Server" do
    @tag :integration
    test "ensure_started and stops" do
      assert :ok = Server.ensure_server_started()
      assert :ok = Server.ensure_server_stopped()
      assert :ok = Server.ensure_server_started()
      assert :ok = Server.ensure_server_stopped()
      assert :ok = Server.ensure_stopped()
    end
  end
end
