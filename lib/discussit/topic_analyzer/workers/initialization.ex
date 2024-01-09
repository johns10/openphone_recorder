defmodule Discussit.TopicAnalyzer.Workers.Initialization do
  use Oban.Worker,
    queue: :topic_analyzer,
    unique: [fields: [:args], states: [:available, :scheduled, :executing, :retryable]]

  alias Discussit.TopicAnalyzer
  alias Discussit.Accounts

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    %{
      "account_id" => account_id,
      "model_id" => _model_id,
      "statements_count" => statements_count
    } = args

    DiscussitWeb.Endpoint.broadcast("account_#{account_id}", "topic_analysis_availability", false)

    FLAME.call(Discussit.TopicAnalyzer.Runner, fn ->
      account = Accounts.get_account!(account_id)
      {:ok, pid} = TopicAnalyzer.start_link(%{})
      TopicAnalyzer.initialize(pid, account, statement_count: statements_count)
    end)

    DiscussitWeb.Endpoint.broadcast("account_#{account_id}", "topic_analysis_availability", true)

    :ok
  end
end
