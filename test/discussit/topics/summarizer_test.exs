defmodule Discussit.Topics.SummarizerTest do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use Discussit.DataCase
  alias Discussit.Topics.Summarizer
  import Discussit.StatementsFixtures
  import Discussit.TopicsFixtures
  import Discussit.AccountsFixtures

  describe "apply" do
    test "summarizes a topic" do
      topic = topic_fixture(%{keywords: [%{keyword: "key", probability: "1.0"}]})
      account = account_fixture()

      bathtub_cleaning_content()
      |> Enum.map(&statement_fixture(%{topic_id: topic.id, content: &1}))

      use_cassette("summarizer_test_apply_summarizes", match_requests_on: [:request_body]) do
        assert {:ok, _} = Summarizer.apply(topic.id, account.id)
      end
    end
  end
end
