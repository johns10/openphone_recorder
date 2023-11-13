defmodule Discussit.TopicAnalyzer.JobTest do
  import Mox
  use Discussit.DataCase
  use Discussit.TopicAnalyzerCase
  use Discussit.ClientCase
  alias Discussit.TopicAnalyzer.Status
  alias Discussit.TopicAnalyzer.Workers.Initialization

  describe "Job queries" do
    import Discussit.AccountsFixtures

    test "getting availability" do
      %{id: account_id} = account_fixture()

      Oban.Testing.with_testing_mode(:manual, fn ->
        %{account_id: account_id}
        |> Initialization.new(schedule_in: 50000)
        |> Oban.insert()
      end)

      assert false == Status.available?(account_id)
      assert true == Status.available?(Ecto.UUID.generate())
    end

    test "getting jobs by account id" do
      %{id: account_id} = account_fixture()

      Oban.Testing.with_testing_mode(:manual, fn ->
        %{account_id: account_id}
        |> Initialization.new(schedule_in: 50000)
        |> Oban.insert()
      end)

      assert [_] = Status.all(account_id)
      assert Enum.count(Status.all(Ecto.UUID.generate())) == 0
    end
  end
end
