defmodule OpenphoneRecorder.ConversationSummarizerTest do
  alias OpenphoneRecorder.ConversationSummarizer
  alias OpenphoneRecorder.Summaries
  alias OpenphoneRecorder.Summaries.Summary

  import OpenphoneRecorder.ParticipantsFixtures
  import OpenphoneRecorder.ConversationsFixtures
  import OpenphoneRecorder.SummarizersFixtures
  import OpenphoneRecorder.PhoneNumbersFixtures
  import OpenphoneRecorder.ContactsFixtures
  import OpenphoneRecorder.TimestampFixtures
  import OpenphoneRecorder.SummariesFixtures
  import OpenphoneRecorder.ConversationSummarizersFixtures

  use OpenphoneRecorder.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  defp conversation(_) do
    conversation = conversation_fixture()
    summarizer = summarizer_fixture()
    contact_one = contact_fixture(%{first_name: "John", last_name: "Smith"})
    contact_two = contact_fixture(%{first_name: "Jane", last_name: "Fonda"})
    phone_number_one = phone_number_fixture(%{contact_id: contact_one.id})
    phone_number_two = phone_number_fixture(%{contact_id: contact_two.id})

    participant_one = participant_fixture(%{phone_number_id: phone_number_one.id})
    participant_two = participant_fixture(%{phone_number_id: phone_number_two.id})

    conversation_summarizer =
      conversation_summarizer_fixture(%{
        conversation_id: conversation.id,
        summarizer_id: summarizer.id
      })

    %{
      conversation: conversation,
      summarizer: summarizer,
      conversation_id: conversation.id,
      participant_one: participant_one,
      participant_two: participant_two,
      conversation_summarizer: conversation_summarizer
    }
  end

  describe "conversation summarizer daily summaries" do
    setup [:conversation]
    import OpenphoneRecorder.StatementsFixtures

    test "happy path", attrs do
      %{conversation: conversation, summarizer: summarizer} = attrs

      bathtub_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, forty_hours_ago()))

      sink_cleaning_contant()
      |> statements_fixture(Map.put(attrs, :occurred_at, eighty_hours_ago()))

      ExVCR.Config.filter_request_headers("Authorization")

      use_cassette("daily_conversation_summaries", match_requests_on: [:request_body]) do
        ConversationSummarizer.create_daily_summaries(conversation, summarizer,
          percentage_reduction: 0.25,
          chunker: :daily,
          max_tokens: 4096
        )

        [summary_one, summary_two] =
          Summaries.list_summaries(preload: :statement_summaries) |> Enum.sort()

        assert "Jane Fonda and John Smith discussed the importance of" <> _ = summary_one.content

        assert summary_one.title == "Cleaning the Kitchen Sink"
        assert Enum.count(summary_one.statement_summaries) == 22
        assert Enum.count(summary_two.statement_summaries) == 18
      end
    end

    test "so many tokens", attrs do
      %{conversation: conversation, summarizer: summarizer} = attrs

      bathtub_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, forty_hours_ago()))

      bathtub_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, forty_hours_ago()))

      bathtub_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, forty_hours_ago()))

      bathtub_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, forty_hours_ago()))

      bathtub_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, forty_hours_ago()))

      bathtub_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, forty_hours_ago()))

      ExVCR.Config.filter_request_headers("Authorization")

      use_cassette("daily_conversation_summaries_over_token_limit",
        match_requests_on: [:request_body]
      ) do
        ConversationSummarizer.create_daily_summaries(conversation, summarizer,
          percentage_reduction: 0.25,
          chunker: :daily,
          max_tokens: 4096
        )
        |> IO.inspect()
      end
    end
  end

  describe "conversation summarizer weekly summaries" do
    setup [:conversation]
    import OpenphoneRecorder.StatementsFixtures

    test "happy path no summaries", attrs do
      %{conversation: conversation, summarizer: summarizer, conversation_summarizer: cs} = attrs

      day_of_week =
        Date.utc_today()
        |> Date.day_of_week()

      summary_fixture(%{
        title: "Cleaning a Bathtub with Magic",
        content:
          "John Smith and Jane Fonda discuss the best way to clean a bathtub, with John planning to use a magical potion made from organic unicorn tears and enchanted pixie dust. Jane advises John to wear gloves and follow instructions carefully, and to use elbow grease and a toothbrush to tackle stubborn stains. Jane also suggests ventilating the bathroom and letting the cleaner sit for a while before scrubbing. John is determined to make the bathtub sparkle and Jane encourages him to be patient and persistent.",
        summary_interval: days_ago_range(day_of_week + 1),
        conversation_summarizer_id: cs.id,
        level: Summary.daily()
      })

      summary_fixture(%{
        title: "Cleaning the Sink: A Team Effort",
        content:
          "John and Jane work together to clean the sink, removing any dishes, utensils, or other items, and using a multipurpose cleaner or mild dish soap with a sponge or non-abrasive scrub brush. They wet the sink first, apply the cleaner, scrub in circular motions, rinse the sink with warm water, and wipe it dry with a cloth or paper towels. The result is a clean and sparkling sink, and a commitment to maintain it regularly.",
        summary_interval: days_ago_range(day_of_week + 2),
        conversation_summarizer_id: cs.id,
        level: Summary.daily()
      })

      ExVCR.Config.filter_request_headers("Authorization")

      use_cassette("weekly_conversation_summaries", match_requests_on: [:request_body]) do
        summaries =
          ConversationSummarizer.create_weekly_summaries(conversation, summarizer,
            max_tokens: 4096
          )

        assert Enum.count(summaries) == 1
      end
    end

    test "happy path previous summary", attrs do
      %{conversation: conversation, summarizer: summarizer, conversation_summarizer: cs} = attrs

      day_of_week =
        Date.utc_today()
        |> Date.day_of_week()

      summary_fixture(%{
        title: "title",
        content: "content",
        summary_interval: weeks_ago_range(2),
        conversation_summarizer_id: cs.id,
        level: Summary.weekly()
      })

      summary_fixture(%{
        title: "Cleaning a Bathtub with Magic",
        content:
          "John Smith and Jane Fonda discuss the best way to clean a bathtub, with John planning to use a magical potion made from organic unicorn tears and enchanted pixie dust. Jane advises John to wear gloves and follow instructions carefully, and to use elbow grease and a toothbrush to tackle stubborn stains. Jane also suggests ventilating the bathroom and letting the cleaner sit for a while before scrubbing. John is determined to make the bathtub sparkle and Jane encourages him to be patient and persistent.",
        summary_interval: days_ago_range(day_of_week + 10),
        conversation_summarizer_id: cs.id,
        level: Summary.daily()
      })

      summary_fixture(%{
        title: "Cleaning the Sink: A Team Effort",
        content:
          "John and Jane work together to clean the sink, removing any dishes, utensils, or other items, and using a multipurpose cleaner or mild dish soap with a sponge or non-abrasive scrub brush. They wet the sink first, apply the cleaner, scrub in circular motions, rinse the sink with warm water, and wipe it dry with a cloth or paper towels. The result is a clean and sparkling sink, and a commitment to maintain it regularly.",
        summary_interval: days_ago_range(day_of_week + 2),
        conversation_summarizer_id: cs.id,
        level: Summary.daily()
      })

      use_cassette("existing_weekly_conversation_summaries", match_requests_on: [:request_body]) do
        ConversationSummarizer.create_weekly_summaries(conversation, summarizer, max_tokens: 4096)
      end
    end
  end
end
