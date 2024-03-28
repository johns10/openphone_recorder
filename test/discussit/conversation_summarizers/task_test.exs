defmodule Discussit.ConversationSummarizers.TaskTest do
  use Discussit.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use Oban.Testing, repo: Discussit.Repo, testing: :manual
  alias Discussit.ConversationSummarizers.Task
  alias Discussit.Summaries.Summary
  import Discussit.ConversationsFixtures
  import Discussit.StatementsFixtures
  import Discussit.SummarizersFixtures
  import Discussit.ConversationSummarizersFixtures
  import Discussit.TimestampFixtures
  import Discussit.PhoneNumbersFixtures
  import Discussit.ParticipantsFixtures
  import Discussit.ContactsFixtures
  import Discussit.AccountsFixtures

  describe "Task" do
    test "inserts" do
      Oban.Testing.with_testing_mode(:manual, fn ->
        %{
          "conversation_summarizer_id" => "asdf",
          "account_id" => "jkl;"
        }
        |> Discussit.ConversationSummarizers.Task.new()
        |> Oban.insert()

        assert [%{args: %{"account_id" => "jkl;", "conversation_summarizer_id" => "asdf"}}] =
                 all_enqueued()
      end)
    end

    test "prevents duplicates" do
      Oban.Testing.with_testing_mode(:manual, fn ->
        attrs = %{"conversation_summarizer_id" => "asdf", "account_id" => "jkl;"}

        attrs
        |> Discussit.ConversationSummarizers.Task.new()
        |> Oban.insert()

        attrs
        |> Discussit.ConversationSummarizers.Task.new()
        |> Oban.insert()

        assert [%{args: %{"account_id" => "jkl;", "conversation_summarizer_id" => "asdf"}}] =
                 all_enqueued()
      end)
    end

    test "actually unique" do
      Oban.Testing.with_testing_mode(:manual, fn ->
        %{"conversation_summarizer_id" => "1", "account_id" => "1"}
        |> Discussit.ConversationSummarizers.Task.new()
        |> Oban.insert()

        %{"conversation_summarizer_id" => "2", "account_id" => "1"}
        |> Discussit.ConversationSummarizers.Task.new()
        |> Oban.insert()

        assert [
                 %{args: %{"conversation_summarizer_id" => "2"}},
                 %{args: %{"conversation_summarizer_id" => "1"}}
               ] = all_enqueued()
      end)
    end

    test "perform" do
      %{id: account_id} = account_fixture()
      contact_one = contact_fixture(%{first_name: "John", last_name: "Doe"})
      contact_two = contact_fixture(%{first_name: "Jane", last_name: "Foe"})
      pn_one = phone_number_fixture(%{value: "12566786789"})
      pn_two = phone_number_fixture(%{value: "12566736789"})

      participant_one =
        participant_fixture(%{phone_number_id: pn_one.id, contact_id: contact_one.id})

      participant_two =
        participant_fixture(%{phone_number_id: pn_two.id, contact_id: contact_two.id})

      %{id: conversation_id} = conversation = conversation_fixture()
      %{id: summarizer_id} = summarizer = custom_summarizer_fixture()

      cs =
        conversation_summarizer_fixture(%{
          summarizer_id: summarizer_id,
          conversation_id: conversation_id
        })
        |> Map.put(:conversation, conversation)
        |> Map.put(:summarizer, summarizer)

      attrs = %{
        conversation_id: conversation_id,
        participant_one: participant_one,
        participant_two: participant_two
      }

      sink_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, days_hours_ago(3, 1)))

      ExVCR.Config.filter_request_headers("Authorization")

      use_cassette("custom_conversation_summaries",
        match_requests_on: [:request_body]
      ) do
        assert :ok ==
                 %{
                   "conversation_summarizer_id" => cs.id,
                   "account_id" => account_id
                 }
                 |> Discussit.ConversationSummarizers.Task.new()
                 |> Ecto.Changeset.apply_action!(:insert)
                 |> Task.perform()
      end

      assert [%Summary{content: "John and Jane notice the dirty sink and" <> _}] =
               Discussit.Summaries.list_summaries()
    end
  end
end
