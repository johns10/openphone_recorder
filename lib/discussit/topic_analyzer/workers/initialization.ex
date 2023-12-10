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
    account = Accounts.get_account!(account_id)
    TopicAnalyzer.Server.ensure_server_started()
    TopicAnalyzer.init(account, statements_count)
    DiscussitWeb.Endpoint.broadcast("account_#{account_id}", "topic_analysis_availability", true)

    :ok
  end
end
