defmodule OpenphoneRecorder.ConversationSummarizerTest do
  alias OpenphoneRecorder.ConversationSummarizer
  import OpenphoneRecorder.TimestampFixtures
  use OpenphoneRecorder.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  describe "conversation summarizer" do
    import OpenphoneRecorder.StatementsFixtures
    import OpenphoneRecorder.ParticipantsFixtures
    import OpenphoneRecorder.ConversationsFixtures
    import OpenphoneRecorder.SummarizersFixtures
    import OpenphoneRecorder.PhoneNumbersFixtures
    import OpenphoneRecorder.ContactsFixtures

    test "summarizes a conversation" do
      conversation = conversation_fixture()
      summarizer = summarizer_fixture()
      contact_one = contact_fixture(%{first_name: "John", last_name: "Smith"})
      contact_two = contact_fixture(%{first_name: "Jane", last_name: "Fonda"})
      phone_number_one = phone_number_fixture(%{contact_id: contact_one.id})
      phone_number_two = phone_number_fixture(%{contact_id: contact_two.id})

      participant_one = participant_fixture(%{phone_number_id: phone_number_one.id})
      participant_two = participant_fixture(%{phone_number_id: phone_number_two.id})

      attrs = %{
        conversation_id: conversation.id,
        participant_one: participant_one,
        participant_two: participant_two
      }

      bathtub_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, twenty_hours_ago()))

      sink_cleaning_contant()
      |> statements_fixture(Map.put(attrs, :occurred_at, sixty_hours_ago()))

      use_cassette("conversation_summarizer_happy_path", match_requests_on: [:request_body]) do
        [summary_one, summary_two] =
          ConversationSummarizer.apply(conversation, summarizer,
            percentage_reduction: 0.25,
            chunker: :temporal,
            max_tokens: 4096
          )

        assert summary_one.content ==
                 "Jane Fonda and John Smith discussed the importance of cleaning the kitchen sink regularly. They agreed to make it a habit and Jane suggested using a multipurpose cleaner or mild dish soap, a sponge or non-abrasive scrub brush, and to wet the sink first. John cleared out the sink and then applied the cleaner, scrubbed it in circular motions, and rinsed it with warm water to remove any residue. Finally, he wiped the sink dry to prevent water spots or streaks from forming."

        assert summary_one.title == "Cleaning the Kitchen Sink"
        assert Enum.count(summary_one.statement_summaries) == 22
        assert Enum.count(summary_two.statement_summaries) == 18
      end
    end
  end
end
