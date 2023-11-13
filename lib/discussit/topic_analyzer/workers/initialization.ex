defmodule Discussit.TopicAnalyzer.Workers.Initialization do
  use Oban.Worker,
    queue: :topic_analyzer,
    unique: [fields: [:args], states: [:available, :scheduled, :executing, :retryable]]

  alias Discussit.TopicAnalyzer
  alias Discussit.Accounts

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"account_id" => account_id}}) do
    DiscussitWeb.Endpoint.broadcast("account_#{account_id}", "topic_analysis_availability", false)
    account = Accounts.get_account!(account_id)
    TopicAnalyzer.Server.ensure_server_started()
    TopicAnalyzer.init(account)
    DiscussitWeb.Endpoint.broadcast("account_#{account_id}", "topic_analysis_availability", true)

    :ok
  end
end
