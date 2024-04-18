defmodule Discussit.ConversationWorker.ImplTest do
  use Discussit.DataCase
  use Discussit.AudioCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Discussit.Summaries.Summary
  alias Discussit.ConversationSummarizer
  alias Discussit.ConversationWorker.Impl
  alias Discussit.ConversationSummarizers.ConversationSummarizer

  import Mox
  import Discussit.ConversationsFixtures
  import Discussit.StatementsFixtures
  import Discussit.SummarizersFixtures
  import Discussit.ConversationSummarizersFixtures
  import Discussit.TimestampFixtures
  import Discussit.PhoneNumbersFixtures
  import Discussit.ParticipantsFixtures
  import Discussit.ContactsFixtures
  import Discussit.SummariesFixtures
  import Discussit.AccountsFixtures
  import Discussit.ModelsFixtures

  setup :set_mox_global

  defp default_opts(account_id) do
    on_summary_created = fn _, _ -> :ok end

    [
      broadcast_function: on_summary_created,
      account_id: account_id,
      openai_config: %{
        api_key: System.get_env("OPENAI_API_KEY"),
        http_options: [recv_timeout: 10 * 60 * 1000],
        organization_key: ""
      }
    ]
  end

  describe "ensure_summarizers_exist" do
    test "works" do
      %{id: conversation_id} = conversation = conversation_fixture()
      %{id: daily_id} = daily_summarizer_fixture()
      %{id: weekly_id} = weekly_summarizer_fixture()
      %{id: monthly_id} = monthly_summarizer_fixture()
      %{id: yearly_id} = yearly_summarizer_fixture()

      assert [
               %ConversationSummarizer{
                 summarizer_id: ^daily_id,
                 conversation_id: ^conversation_id
               },
               %ConversationSummarizer{
                 summarizer_id: ^weekly_id,
                 conversation_id: ^conversation_id
               },
               %ConversationSummarizer{
                 summarizer_id: ^monthly_id,
                 conversation_id: ^conversation_id
               },
               %ConversationSummarizer{
                 summarizer_id: ^yearly_id,
                 conversation_id: ^conversation_id
               }
             ] = Impl.ensure_conversation_summarizers_exist(%{conversation: conversation})
    end

    test "handles existing" do
      %{id: conversation_id} = conversation = conversation_fixture()
      %{id: daily_id} = daily_summarizer_fixture()
      %{id: weekly_id} = weekly_summarizer_fixture()
      %{id: monthly_id} = monthly_summarizer_fixture()
      %{id: yearly_id} = yearly_summarizer_fixture()

      %{id: cs_id} =
        conversation_summarizer_fixture(%{
          summarizer_id: daily_id,
          conversation_id: conversation.id
        })

      assert [
               %ConversationSummarizer{
                 id: ^cs_id,
                 summarizer_id: ^daily_id,
                 conversation_id: ^conversation_id
               },
               %ConversationSummarizer{
                 summarizer_id: ^weekly_id,
                 conversation_id: ^conversation_id
               },
               %ConversationSummarizer{
                 summarizer_id: ^monthly_id,
                 conversation_id: ^conversation_id
               },
               %ConversationSummarizer{
                 summarizer_id: ^yearly_id,
                 conversation_id: ^conversation_id
               }
             ] = Impl.ensure_conversation_summarizers_exist(%{conversation: conversation})
    end

    test "throws errors" do
      daily_summarizer_fixture()
      weekly_summarizer_fixture()
      monthly_summarizer_fixture()
      yearly_summarizer_fixture()

      assert [] ==
               Impl.ensure_conversation_summarizers_exist(%{
                 conversation: %{id: Ecto.UUID.generate()}
               })
               |> Enum.reject(&(&1 == :error))
    end
  end

  describe "daily" do
    test "summarizes over token limit" do
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
      %{id: daily_id} = daily = daily_summarizer_fixture()

      cs =
        conversation_summarizer_fixture(%{
          summarizer_id: daily_id,
          conversation_id: conversation_id
        })
        |> Map.put(:conversation, conversation)
        |> Map.put(:summarizer, daily)

      attrs = %{
        conversation_id: conversation_id,
        participant_one: participant_one,
        participant_two: participant_two
      }

      bathtub_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, days_hours_ago(1, 1)))

      sink_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, days_hours_ago(1, 2)))

      floor_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, days_hours_ago(1, 3)))

      toilet_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, days_hours_ago(1, 4)))

      shower_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, days_hours_ago(1, 5)))

      floor_cleaning_content_2()
      |> statements_fixture(Map.put(attrs, :occurred_at, days_hours_ago(1, 6)))

      oven_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, days_hours_ago(1, 7)))

      cabinet_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, days_hours_ago(1, 8)))

      baseboard_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, days_hours_ago(1, 9)))

      wall_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, days_hours_ago(1, 10)))

      ceiling_fan_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, days_hours_ago(1, 11)))

      ExVCR.Config.filter_request_headers("Authorization")

      use_cassette("daily_conversation_summaries_over_token_limit",
        match_requests_on: [:request_body]
      ) do
        opts =
          default_opts(account_id)
          |> Keyword.put(:max_text_output_count, 442)
          |> Keyword.put(:max_context_count, 4096)

        assert [%{content: "Jane Foe and John Doe have playful" <> _}] =
                 Impl.create_daily_summaries(cs, opts)
      end
    end

    test "summarizes" do
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
      %{id: daily_id} = daily = daily_summarizer_fixture()

      cs =
        conversation_summarizer_fixture(%{
          summarizer_id: daily_id,
          conversation_id: conversation_id
        })
        |> Map.put(:conversation, conversation)
        |> Map.put(:summarizer, daily)

      attrs = %{
        conversation_id: conversation_id,
        participant_one: participant_one,
        participant_two: participant_two
      }

      sink_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, days_hours_ago(3, 1)))

      ExVCR.Config.filter_request_headers("Authorization")

      use_cassette("daily_conversation_summaries", match_requests_on: [:request_body]) do
        assert [%Summary{content: "John and Jane notice the dirty sink and" <> _}] =
                 Impl.create_daily_summaries(cs, default_opts(account_id))
      end
    end
  end

  describe "weekly" do
    test "summarizes" do
      %{id: account_id} = account_fixture()
      contact_one = contact_fixture(%{first_name: "John", last_name: "Doe"})
      contact_two = contact_fixture(%{first_name: "Jane", last_name: "Foe"})
      pn_one = phone_number_fixture(%{value: "12566786789"})
      pn_two = phone_number_fixture(%{value: "12566736789"})
      participant_fixture(%{phone_number_id: pn_one.id, contact_id: contact_one.id})
      participant_fixture(%{phone_number_id: pn_two.id, contact_id: contact_two.id})
      %{id: conversation_id} = conversation = conversation_fixture()
      %{id: weekly_id} = weekly = weekly_summarizer_fixture()

      cs =
        conversation_summarizer_fixture(%{
          summarizer_id: weekly_id,
          conversation_id: conversation_id
        })
        |> Map.put(:conversation, conversation)
        |> Map.put(:summarizer, weekly)

      beginning_of_week =
        Date.utc_today()
        |> Date.beginning_of_week()
        |> Date.add(-7)

      summary_fixture(%{
        title: "Cleaning a Bathtub with Magic",
        content:
          "Maintaining a clean and hygienic sink is important for the overall freshness of the kitchen. Jane and John agree to make it a habit to clean the sink regularly. They discuss the steps to clean the sink, including removing dishes and utensils, wetting the sink, applying a mild cleaner or dish soap, scrubbing the sink, rinsing it thoroughly, and drying it with a cloth or paper towels. They emphasize the importance of removing all cleaner or soap residue and paying attention to stubborn stains. They also mention the use of non-abrasive cleaning products and tools. Jane and John are satisfied with the results and plan to maintain the cleanliness of the sink to prevent it from getting dirty again.",
        summary_interval: day_range(beginning_of_week),
        conversation_summarizer_id: cs.id,
        level: Summary.daily()
      })

      summary_fixture(%{
        title: "Cleaning the Sink: A Team Effort",
        content:
          "John Doe asks Jane Foe if she has ever cleaned a bathtub before. Jane Foe says she has and it's necessary but not exciting. John Doe admits he has been putting off cleaning his bathtub and it's starting to look bad. Jane Foe warns him about online cleaning products and asks about the ingredients of the one he found. John Doe says it's a secret formula made from organic unicorn tears and enchanted pixie dust. Jane Foe laughs and tells him to be careful and follow instructions. John Doe agrees and says he will wear protective gear. Jane Foe advises him to use elbow grease and ventilate the bathroom. John Doe agrees and says he will let the cleaner sit and repeat the process if needed. Jane Foe encourages him and says the end result will be worth it. John Doe thanks her and decides to clean the sink as well. Jane Foe agrees and says it's time to tackle it.\n\nJohn Doe and Jane Foe discuss the process of cleaning a sink. They agree to remove all dishes and utensils from the sink before starting. Jane suggests using a multipurpose cleaner or mild dish soap, along with a sponge or non-abrasive scrub brush. John gathers the supplies while Jane clears out the sink. They decide to wet the sink first before applying the cleaner, and John is instructed to scrub the sink in circular motions. After scrubbing, they rinse the sink thoroughly with warm water to remove any residue. They dry the sink with a cloth or paper towels to prevent water spots. Both are satisfied with the clean sink and agree to maintain it regularly. The conversation then takes a humorous turn as they discuss unconventional cleaning methods for floors, toilets, and showers. John prefers traditional cleaning methods, while Jane suggests using toothbrushes, ketchup and mustard, milk, feathers, spaghetti, loofah sponges, antacid tablets, glitter, mayonnaise, wildflower seeds, squirrels, melted chocolate and coconut oil, peanut butter, hairdryers, singing frogs, and whipped cream. They eventually agree that traditional cleaning methods are the most effective, but Jane encourages John to try some of his unique ideas for a touch of whimsy. They end the conversation by discussing John's question about cleaning floors, with Jane suggesting using old socks as cleaning gloves and John suggesting using whipped cream or confetti.\n\nJane and John continue their conversation about unconventional cleaning methods. Jane suggests using glitter to attract dirt and grime in the oven, while John suggests using marshmallows to scrub away the dirt. They both agree that these methods may leave a messy residue. Jane then suggests using a mixture of honey and vinegar, but John is concerned about the smell. Jane jokingly suggests using a pet parrot to peck away the grime, but John dismisses the idea. They discuss using a balloon-powered cleaning system, meditating, and using a mixture of banana peel and toothpaste, but John decides to stick to traditional methods. They then discuss cleaning kitchen cabinets, with Jane suggesting using a fluffy kitten to dust and John suggesting using mashed potatoes. They also discuss using a feather duster on a remote-controlled car and playing classical music. They eventually agree that using a regular cleaning spray and microfiber cloth is the most reliable method. They continue their conversation about cleaning baseboards, walls, and ceiling fans, with Jane suggesting using a feather boa, whipped cream, and bubble bath, and John suggesting using a damp cloth and mild soap. They also discuss using a pillowcase to clean fan blades and emphasize the importance of safety when cleaning high areas. They conclude by discussing the importance of regular maintenance for ceiling fans.",
        summary_interval: beginning_of_week |> Date.add(1) |> day_range(),
        conversation_summarizer_id: cs.id,
        level: Summary.daily()
      })

      use_cassette("weekly_conversation_summaries", match_requests_on: [:request_body]) do
        assert [
                 %Summary{
                   content:
                     "Throughout the week, Jane and John discussed the importance of maintaining" <>
                       _
                 }
               ] = Impl.create_weekly_summaries(cs, default_opts(account_id))
      end
    end

    test "skips previous summary" do
      %{id: account_id} = account_fixture()
      contact_one = contact_fixture(%{first_name: "John", last_name: "Doe"})
      contact_two = contact_fixture(%{first_name: "Jane", last_name: "Foe"})
      pn_one = phone_number_fixture(%{value: "12566786789"})
      pn_two = phone_number_fixture(%{value: "12566736789"})
      participant_fixture(%{phone_number_id: pn_one.id, contact_id: contact_one.id})
      participant_fixture(%{phone_number_id: pn_two.id, contact_id: contact_two.id})
      %{id: conversation_id} = conversation = conversation_fixture()
      %{id: weekly_id} = weekly = weekly_summarizer_fixture()

      cs =
        conversation_summarizer_fixture(%{
          summarizer_id: weekly_id,
          conversation_id: conversation_id
        })
        |> Map.put(:conversation, conversation)
        |> Map.put(:summarizer, weekly)

      summary_fixture(%{
        title: "title",
        content: "content",
        summary_interval: weeks_ago_range(3),
        conversation_summarizer_id: cs.id,
        level: Summary.weekly()
      })

      summary_fixture(%{
        title: "Cleaning a Bathtub with Magic",
        content:
          "Maintaining a clean and hygienic sink is important for the overall freshness of the kitchen. Jane and John agree to make it a habit to clean the sink regularly. They discuss the steps to clean the sink, including removing dishes and utensils, wetting the sink, applying a mild cleaner or dish soap, scrubbing the sink, rinsing it thoroughly, and drying it with a cloth or paper towels. They emphasize the importance of removing all cleaner or soap residue and paying attention to stubborn stains. They also mention the use of non-abrasive cleaning products and tools. Jane and John are satisfied with the results and plan to maintain the cleanliness of the sink to prevent it from getting dirty again.",
        summary_interval: day_range(days_ago(21)),
        conversation_summarizer_id: cs.id,
        level: Summary.daily()
      })

      summary_fixture(%{
        title: "Cleaning the Sink: A Team Effort",
        content:
          "John Doe asks Jane Foe if she has ever cleaned a bathtub before. Jane Foe says she has and it's necessary but not exciting. John Doe admits he has been putting off cleaning his bathtub and it's starting to look bad. Jane Foe warns him about online cleaning products and asks about the ingredients of the one he found. John Doe says it's a secret formula made from organic unicorn tears and enchanted pixie dust. Jane Foe laughs and tells him to be careful and follow instructions. John Doe agrees and says he will wear protective gear. Jane Foe advises him to use elbow grease and ventilate the bathroom. John Doe agrees and says he will let the cleaner sit and repeat the process if needed. Jane Foe encourages him and says the end result will be worth it. John Doe thanks her and decides to clean the sink as well. Jane Foe agrees and says it's time to tackle it.\n\nJohn Doe and Jane Foe discuss the process of cleaning a sink. They agree to remove all dishes and utensils from the sink before starting. Jane suggests using a multipurpose cleaner or mild dish soap, along with a sponge or non-abrasive scrub brush. John gathers the supplies while Jane clears out the sink. They decide to wet the sink first before applying the cleaner, and John is instructed to scrub the sink in circular motions. After scrubbing, they rinse the sink thoroughly with warm water to remove any residue. They dry the sink with a cloth or paper towels to prevent water spots. Both are satisfied with the clean sink and agree to maintain it regularly. The conversation then takes a humorous turn as they discuss unconventional cleaning methods for floors, toilets, and showers. John prefers traditional cleaning methods, while Jane suggests using toothbrushes, ketchup and mustard, milk, feathers, spaghetti, loofah sponges, antacid tablets, glitter, mayonnaise, wildflower seeds, squirrels, melted chocolate and coconut oil, peanut butter, hairdryers, singing frogs, and whipped cream. They eventually agree that traditional cleaning methods are the most effective, but Jane encourages John to try some of his unique ideas for a touch of whimsy. They end the conversation by discussing John's question about cleaning floors, with Jane suggesting using old socks as cleaning gloves and John suggesting using whipped cream or confetti.\n\nJane and John continue their conversation about unconventional cleaning methods. Jane suggests using glitter to attract dirt and grime in the oven, while John suggests using marshmallows to scrub away the dirt. They both agree that these methods may leave a messy residue. Jane then suggests using a mixture of honey and vinegar, but John is concerned about the smell. Jane jokingly suggests using a pet parrot to peck away the grime, but John dismisses the idea. They discuss using a balloon-powered cleaning system, meditating, and using a mixture of banana peel and toothpaste, but John decides to stick to traditional methods. They then discuss cleaning kitchen cabinets, with Jane suggesting using a fluffy kitten to dust and John suggesting using mashed potatoes. They also discuss using a feather duster on a remote-controlled car and playing classical music. They eventually agree that using a regular cleaning spray and microfiber cloth is the most reliable method. They continue their conversation about cleaning baseboards, walls, and ceiling fans, with Jane suggesting using a feather boa, whipped cream, and bubble bath, and John suggesting using a damp cloth and mild soap. They also discuss using a pillowcase to clean fan blades and emphasize the importance of safety when cleaning high areas. They conclude by discussing the importance of regular maintenance for ceiling fans.",
        summary_interval: day_range(days_ago(14)),
        conversation_summarizer_id: cs.id,
        level: Summary.daily()
      })

      use_cassette("existing_weekly_conversation_summaries", match_requests_on: [:request_body]) do
        assert [
                 %{
                   content:
                     "John Doe and Jane Foe engage in a conversation about cleaning a bathtub and sink." <>
                       _
                 }
               ] = Impl.create_weekly_summaries(cs, default_opts(account_id))
      end
    end

    test "skips this weeks summary" do
      %{id: account_id} = account_fixture()
      contact_one = contact_fixture(%{first_name: "John", last_name: "Doe"})
      contact_two = contact_fixture(%{first_name: "Jane", last_name: "Foe"})
      pn_one = phone_number_fixture(%{value: "12566786789"})
      pn_two = phone_number_fixture(%{value: "12566736789"})
      participant_fixture(%{phone_number_id: pn_one.id, contact_id: contact_one.id})
      participant_fixture(%{phone_number_id: pn_two.id, contact_id: contact_two.id})
      %{id: conversation_id} = conversation = conversation_fixture()
      %{id: weekly_id} = weekly = weekly_summarizer_fixture()

      cs =
        conversation_summarizer_fixture(%{
          summarizer_id: weekly_id,
          conversation_id: conversation_id
        })
        |> Map.put(:conversation, conversation)
        |> Map.put(:summarizer, weekly)

      start_of_week =
        Date.utc_today()
        |> Date.beginning_of_week()

      summary_fixture(%{
        title: "Cleaning a Bathtub with Magic",
        content:
          "Maintaining a clean and hygienic sink is important for the overall freshness of the kitchen. Jane and John agree to make it a habit to clean the sink regularly. They discuss the steps to clean the sink, including removing dishes and utensils, wetting the sink, applying a mild cleaner or dish soap, scrubbing the sink, rinsing it thoroughly, and drying it with a cloth or paper towels. They emphasize the importance of removing all cleaner or soap residue and paying attention to stubborn stains. They also mention the use of non-abrasive cleaning products and tools. Jane and John are satisfied with the results and plan to maintain the cleanliness of the sink to prevent it from getting dirty again.",
        summary_interval: start_of_week |> Date.add(1) |> day_range(),
        conversation_summarizer_id: cs.id,
        level: Summary.daily()
      })

      summary_fixture(%{
        title: "Cleaning the Sink: A Team Effort",
        content:
          "John Doe asks Jane Foe if she has ever cleaned a bathtub before. Jane Foe says she has and it's necessary but not exciting. John Doe admits he has been putting off cleaning his bathtub and it's starting to look bad. Jane Foe warns him about online cleaning products and asks about the ingredients of the one he found. John Doe says it's a secret formula made from organic unicorn tears and enchanted pixie dust. Jane Foe laughs and tells him to be careful and follow instructions. John Doe agrees and says he will wear protective gear. Jane Foe advises him to use elbow grease and ventilate the bathroom. John Doe agrees and says he will let the cleaner sit and repeat the process if needed. Jane Foe encourages him and says the end result will be worth it. John Doe thanks her and decides to clean the sink as well. Jane Foe agrees and says it's time to tackle it.\n\nJohn Doe and Jane Foe discuss the process of cleaning a sink. They agree to remove all dishes and utensils from the sink before starting. Jane suggests using a multipurpose cleaner or mild dish soap, along with a sponge or non-abrasive scrub brush. John gathers the supplies while Jane clears out the sink. They decide to wet the sink first before applying the cleaner, and John is instructed to scrub the sink in circular motions. After scrubbing, they rinse the sink thoroughly with warm water to remove any residue. They dry the sink with a cloth or paper towels to prevent water spots. Both are satisfied with the clean sink and agree to maintain it regularly. The conversation then takes a humorous turn as they discuss unconventional cleaning methods for floors, toilets, and showers. John prefers traditional cleaning methods, while Jane suggests using toothbrushes, ketchup and mustard, milk, feathers, spaghetti, loofah sponges, antacid tablets, glitter, mayonnaise, wildflower seeds, squirrels, melted chocolate and coconut oil, peanut butter, hairdryers, singing frogs, and whipped cream. They eventually agree that traditional cleaning methods are the most effective, but Jane encourages John to try some of his unique ideas for a touch of whimsy. They end the conversation by discussing John's question about cleaning floors, with Jane suggesting using old socks as cleaning gloves and John suggesting using whipped cream or confetti.\n\nJane and John continue their conversation about unconventional cleaning methods. Jane suggests using glitter to attract dirt and grime in the oven, while John suggests using marshmallows to scrub away the dirt. They both agree that these methods may leave a messy residue. Jane then suggests using a mixture of honey and vinegar, but John is concerned about the smell. Jane jokingly suggests using a pet parrot to peck away the grime, but John dismisses the idea. They discuss using a balloon-powered cleaning system, meditating, and using a mixture of banana peel and toothpaste, but John decides to stick to traditional methods. They then discuss cleaning kitchen cabinets, with Jane suggesting using a fluffy kitten to dust and John suggesting using mashed potatoes. They also discuss using a feather duster on a remote-controlled car and playing classical music. They eventually agree that using a regular cleaning spray and microfiber cloth is the most reliable method. They continue their conversation about cleaning baseboards, walls, and ceiling fans, with Jane suggesting using a feather boa, whipped cream, and bubble bath, and John suggesting using a damp cloth and mild soap. They also discuss using a pillowcase to clean fan blades and emphasize the importance of safety when cleaning high areas. They conclude by discussing the importance of regular maintenance for ceiling fans.",
        summary_interval: start_of_week |> Date.add(2) |> day_range(),
        conversation_summarizer_id: cs.id,
        level: Summary.daily()
      })

      assert [] == Impl.create_weekly_summaries(cs, default_opts(account_id))
    end
  end

  describe "monthly" do
    test "summarizes" do
      %{id: account_id} = account_fixture()
      %{id: conversation_id} = conversation = conversation_fixture()
      %{id: monthly_id} = monthly = monthly_summarizer_fixture()

      cs =
        conversation_summarizer_fixture(%{
          summarizer_id: monthly_id,
          conversation_id: conversation_id
        })
        |> Map.put(:conversation, conversation)
        |> Map.put(:summarizer, monthly)

      summary_fixture(%{
        title: "Cleaning a Bathtub with Magic",
        content:
          "Maintaining a clean and hygienic sink is important for the overall freshness of the kitchen. Jane and John agree to make it a habit to clean the sink regularly. They discuss the steps to clean the sink, including removing dishes and utensils, wetting the sink, applying a mild cleaner or dish soap, scrubbing the sink, rinsing it thoroughly, and drying it with a cloth or paper towels. They emphasize the importance of removing all cleaner or soap residue and paying attention to stubborn stains. They also mention the use of non-abrasive cleaning products and tools. Jane and John are satisfied with the results and plan to maintain the cleanliness of the sink to prevent it from getting dirty again.",
        summary_interval: months_weeks_ago(1, 1) |> day_range(),
        conversation_summarizer_id: cs.id,
        level: Summary.daily()
      })

      summary_fixture(%{
        title: "Cleaning the Sink: A Team Effort",
        content:
          "John Doe asks Jane Foe if she has ever cleaned a bathtub before. Jane Foe says she has and it's necessary but not exciting. John Doe admits he has been putting off cleaning his bathtub and it's starting to look bad. Jane Foe warns him about online cleaning products and asks about the ingredients of the one he found. John Doe says it's a secret formula made from organic unicorn tears and enchanted pixie dust. Jane Foe laughs and tells him to be careful and follow instructions. John Doe agrees and says he will wear protective gear. Jane Foe advises him to use elbow grease and ventilate the bathroom. John Doe agrees and says he will let the cleaner sit and repeat the process if needed. Jane Foe encourages him and says the end result will be worth it. John Doe thanks her and decides to clean the sink as well. Jane Foe agrees and says it's time to tackle it.\n\nJohn Doe and Jane Foe discuss the process of cleaning a sink. They agree to remove all dishes and utensils from the sink before starting. Jane suggests using a multipurpose cleaner or mild dish soap, along with a sponge or non-abrasive scrub brush. John gathers the supplies while Jane clears out the sink. They decide to wet the sink first before applying the cleaner, and John is instructed to scrub the sink in circular motions. After scrubbing, they rinse the sink thoroughly with warm water to remove any residue. They dry the sink with a cloth or paper towels to prevent water spots. Both are satisfied with the clean sink and agree to maintain it regularly. The conversation then takes a humorous turn as they discuss unconventional cleaning methods for floors, toilets, and showers. John prefers traditional cleaning methods, while Jane suggests using toothbrushes, ketchup and mustard, milk, feathers, spaghetti, loofah sponges, antacid tablets, glitter, mayonnaise, wildflower seeds, squirrels, melted chocolate and coconut oil, peanut butter, hairdryers, singing frogs, and whipped cream. They eventually agree that traditional cleaning methods are the most effective, but Jane encourages John to try some of his unique ideas for a touch of whimsy. They end the conversation by discussing John's question about cleaning floors, with Jane suggesting using old socks as cleaning gloves and John suggesting using whipped cream or confetti.\n\nJane and John continue their conversation about unconventional cleaning methods. Jane suggests using glitter to attract dirt and grime in the oven, while John suggests using marshmallows to scrub away the dirt. They both agree that these methods may leave a messy residue. Jane then suggests using a mixture of honey and vinegar, but John is concerned about the smell. Jane jokingly suggests using a pet parrot to peck away the grime, but John dismisses the idea. They discuss using a balloon-powered cleaning system, meditating, and using a mixture of banana peel and toothpaste, but John decides to stick to traditional methods. They then discuss cleaning kitchen cabinets, with Jane suggesting using a fluffy kitten to dust and John suggesting using mashed potatoes. They also discuss using a feather duster on a remote-controlled car and playing classical music. They eventually agree that using a regular cleaning spray and microfiber cloth is the most reliable method. They continue their conversation about cleaning baseboards, walls, and ceiling fans, with Jane suggesting using a feather boa, whipped cream, and bubble bath, and John suggesting using a damp cloth and mild soap. They also discuss using a pillowcase to clean fan blades and emphasize the importance of safety when cleaning high areas. They conclude by discussing the importance of regular maintenance for ceiling fans.",
        summary_interval: months_weeks_ago(1, 2) |> day_range(),
        conversation_summarizer_id: cs.id,
        level: Summary.weekly()
      })

      use_cassette("monthly_conversation_summaries", match_requests_on: [:request_body]) do
        assert [
                 %Summary{
                   content:
                     "In the last month, Jane and John have made it a priority to maintain a clean" <>
                       _
                 }
               ] = Impl.create_monthly_summaries(cs, default_opts(account_id))
      end
    end

    test "skips previous summary" do
      %{id: account_id} = account_fixture()
      %{id: conversation_id} = conversation = conversation_fixture()
      %{id: monthly_id} = monthly = monthly_summarizer_fixture()

      cs =
        conversation_summarizer_fixture(%{
          summarizer_id: monthly_id,
          conversation_id: conversation_id
        })
        |> Map.put(:conversation, conversation)
        |> Map.put(:summarizer, monthly)

      summary_fixture(%{
        title: "title",
        content: "content",
        summary_interval: months_ago_range(4),
        conversation_summarizer_id: cs.id,
        level: Summary.monthly()
      })

      summary_fixture(%{
        title: "Cleaning the Sink: A Team Effort",
        content:
          "John Doe asks Jane Foe if she has ever cleaned a bathtub before. Jane Foe says she has and it's necessary but not exciting. John Doe admits he has been putting off cleaning his bathtub and it's starting to look bad. Jane Foe warns him about online cleaning products and asks about the ingredients of the one he found. John Doe says it's a secret formula made from organic unicorn tears and enchanted pixie dust. Jane Foe laughs and tells him to be careful and follow instructions. John Doe agrees and says he will wear protective gear. Jane Foe advises him to use elbow grease and ventilate the bathroom. John Doe agrees and says he will let the cleaner sit and repeat the process if needed. Jane Foe encourages him and says the end result will be worth it. John Doe thanks her and decides to clean the sink as well. Jane Foe agrees and says it's time to tackle it.\n\nJohn Doe and Jane Foe discuss the process of cleaning a sink. They agree to remove all dishes and utensils from the sink before starting. Jane suggests using a multipurpose cleaner or mild dish soap, along with a sponge or non-abrasive scrub brush. John gathers the supplies while Jane clears out the sink. They decide to wet the sink first before applying the cleaner, and John is instructed to scrub the sink in circular motions. After scrubbing, they rinse the sink thoroughly with warm water to remove any residue. They dry the sink with a cloth or paper towels to prevent water spots. Both are satisfied with the clean sink and agree to maintain it regularly. The conversation then takes a humorous turn as they discuss unconventional cleaning methods for floors, toilets, and showers. John prefers traditional cleaning methods, while Jane suggests using toothbrushes, ketchup and mustard, milk, feathers, spaghetti, loofah sponges, antacid tablets, glitter, mayonnaise, wildflower seeds, squirrels, melted chocolate and coconut oil, peanut butter, hairdryers, singing frogs, and whipped cream. They eventually agree that traditional cleaning methods are the most effective, but Jane encourages John to try some of his unique ideas for a touch of whimsy. They end the conversation by discussing John's question about cleaning floors, with Jane suggesting using old socks as cleaning gloves and John suggesting using whipped cream or confetti.\n\nJane and John continue their conversation about unconventional cleaning methods. Jane suggests using glitter to attract dirt and grime in the oven, while John suggests using marshmallows to scrub away the dirt. They both agree that these methods may leave a messy residue. Jane then suggests using a mixture of honey and vinegar, but John is concerned about the smell. Jane jokingly suggests using a pet parrot to peck away the grime, but John dismisses the idea. They discuss using a balloon-powered cleaning system, meditating, and using a mixture of banana peel and toothpaste, but John decides to stick to traditional methods. They then discuss cleaning kitchen cabinets, with Jane suggesting using a fluffy kitten to dust and John suggesting using mashed potatoes. They also discuss using a feather duster on a remote-controlled car and playing classical music. They eventually agree that using a regular cleaning spray and microfiber cloth is the most reliable method. They continue their conversation about cleaning baseboards, walls, and ceiling fans, with Jane suggesting using a feather boa, whipped cream, and bubble bath, and John suggesting using a damp cloth and mild soap. They also discuss using a pillowcase to clean fan blades and emphasize the importance of safety when cleaning high areas. They conclude by discussing the importance of regular maintenance for ceiling fans.",
        summary_interval: months_weeks_ago(3, 1) |> day_range(),
        conversation_summarizer_id: cs.id,
        level: Summary.daily()
      })

      summary_fixture(%{
        title: "title",
        content: "content",
        summary_interval: months_ago_range(3),
        conversation_summarizer_id: cs.id,
        level: Summary.monthly()
      })

      summary_fixture(%{
        title: "Cleaning a Bathtub with Magic",
        content:
          "Maintaining a clean and hygienic sink is important for the overall freshness of the kitchen. Jane and John agree to make it a habit to clean the sink regularly. They discuss the steps to clean the sink, including removing dishes and utensils, wetting the sink, applying a mild cleaner or dish soap, scrubbing the sink, rinsing it thoroughly, and drying it with a cloth or paper towels. They emphasize the importance of removing all cleaner or soap residue and paying attention to stubborn stains. They also mention the use of non-abrasive cleaning products and tools. Jane and John are satisfied with the results and plan to maintain the cleanliness of the sink to prevent it from getting dirty again.",
        summary_interval: months_weeks_ago(2, 2) |> day_range(),
        conversation_summarizer_id: cs.id,
        level: Summary.daily()
      })

      ExVCR.Config.filter_request_headers("Authorization")

      use_cassette("existing_monthly_conversation_summaries", match_requests_on: [:request_body]) do
        assert [
                 %{content: "In the last month, Jane and John have made" <> _}
               ] = Impl.create_monthly_summaries(cs, default_opts(account_id))
      end
    end

    test "skips this months summary" do
      %{id: account_id} = account_fixture()
      %{id: conversation_id} = conversation = conversation_fixture()
      %{id: monthly_id} = monthly = monthly_summarizer_fixture()

      cs =
        conversation_summarizer_fixture(%{
          summarizer_id: monthly_id,
          conversation_id: conversation_id
        })
        |> Map.put(:conversation, conversation)
        |> Map.put(:summarizer, monthly)

      start_of_month =
        Date.utc_today()
        |> Date.beginning_of_month()

      summary_fixture(%{
        title: "Cleaning a Bathtub with Magic",
        content:
          "Maintaining a clean and hygienic sink is important for the overall freshness of the kitchen. Jane and John agree to make it a habit to clean the sink regularly. They discuss the steps to clean the sink, including removing dishes and utensils, wetting the sink, applying a mild cleaner or dish soap, scrubbing the sink, rinsing it thoroughly, and drying it with a cloth or paper towels. They emphasize the importance of removing all cleaner or soap residue and paying attention to stubborn stains. They also mention the use of non-abrasive cleaning products and tools. Jane and John are satisfied with the results and plan to maintain the cleanliness of the sink to prevent it from getting dirty again.",
        summary_interval: start_of_month |> Date.add(1) |> day_range(),
        conversation_summarizer_id: cs.id,
        level: Summary.daily()
      })

      summary_fixture(%{
        title: "Cleaning the Sink: A Team Effort",
        content:
          "John Doe asks Jane Foe if she has ever cleaned a bathtub before. Jane Foe says she has and it's necessary but not exciting. John Doe admits he has been putting off cleaning his bathtub and it's starting to look bad. Jane Foe warns him about online cleaning products and asks about the ingredients of the one he found. John Doe says it's a secret formula made from organic unicorn tears and enchanted pixie dust. Jane Foe laughs and tells him to be careful and follow instructions. John Doe agrees and says he will wear protective gear. Jane Foe advises him to use elbow grease and ventilate the bathroom. John Doe agrees and says he will let the cleaner sit and repeat the process if needed. Jane Foe encourages him and says the end result will be worth it. John Doe thanks her and decides to clean the sink as well. Jane Foe agrees and says it's time to tackle it.\n\nJohn Doe and Jane Foe discuss the process of cleaning a sink. They agree to remove all dishes and utensils from the sink before starting. Jane suggests using a multipurpose cleaner or mild dish soap, along with a sponge or non-abrasive scrub brush. John gathers the supplies while Jane clears out the sink. They decide to wet the sink first before applying the cleaner, and John is instructed to scrub the sink in circular motions. After scrubbing, they rinse the sink thoroughly with warm water to remove any residue. They dry the sink with a cloth or paper towels to prevent water spots. Both are satisfied with the clean sink and agree to maintain it regularly. The conversation then takes a humorous turn as they discuss unconventional cleaning methods for floors, toilets, and showers. John prefers traditional cleaning methods, while Jane suggests using toothbrushes, ketchup and mustard, milk, feathers, spaghetti, loofah sponges, antacid tablets, glitter, mayonnaise, wildflower seeds, squirrels, melted chocolate and coconut oil, peanut butter, hairdryers, singing frogs, and whipped cream. They eventually agree that traditional cleaning methods are the most effective, but Jane encourages John to try some of his unique ideas for a touch of whimsy. They end the conversation by discussing John's question about cleaning floors, with Jane suggesting using old socks as cleaning gloves and John suggesting using whipped cream or confetti.\n\nJane and John continue their conversation about unconventional cleaning methods. Jane suggests using glitter to attract dirt and grime in the oven, while John suggests using marshmallows to scrub away the dirt. They both agree that these methods may leave a messy residue. Jane then suggests using a mixture of honey and vinegar, but John is concerned about the smell. Jane jokingly suggests using a pet parrot to peck away the grime, but John dismisses the idea. They discuss using a balloon-powered cleaning system, meditating, and using a mixture of banana peel and toothpaste, but John decides to stick to traditional methods. They then discuss cleaning kitchen cabinets, with Jane suggesting using a fluffy kitten to dust and John suggesting using mashed potatoes. They also discuss using a feather duster on a remote-controlled car and playing classical music. They eventually agree that using a regular cleaning spray and microfiber cloth is the most reliable method. They continue their conversation about cleaning baseboards, walls, and ceiling fans, with Jane suggesting using a feather boa, whipped cream, and bubble bath, and John suggesting using a damp cloth and mild soap. They also discuss using a pillowcase to clean fan blades and emphasize the importance of safety when cleaning high areas. They conclude by discussing the importance of regular maintenance for ceiling fans.",
        summary_interval: start_of_month |> Date.add(2) |> day_range(),
        conversation_summarizer_id: cs.id,
        level: Summary.daily()
      })

      assert [] == Impl.create_monthly_summaries(cs, default_opts(account_id))
    end

    test "summarizes long conversations into the token limit" do
      %{id: account_id} = account_fixture()
      %{id: conversation_id} = conversation = conversation_fixture()
      %{id: monthly_id} = monthly = monthly_summarizer_fixture()

      cs =
        conversation_summarizer_fixture(%{
          summarizer_id: monthly_id,
          conversation_id: conversation_id
        })
        |> Map.put(:conversation, conversation)
        |> Map.put(:summarizer, monthly)

      long_daily_summaries(cs.id)

      use_cassette("long_monthly_conversation_summary", match_requests_on: [:request_body]) do
        Impl.create_monthly_summaries(cs, default_opts(account_id))
      end
    end
  end

  describe "custom summarizers" do
    test "summarizes" do
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
        assert [%Summary{content: "John and Jane notice the dirty sink and decide" <> _}] =
                 Impl.create_custom_summary(cs, default_opts(account_id))
      end
    end

    test "custom summarizers over token limit" do
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
      %{id: summarizer_id} = daily = custom_summarizer_fixture()

      cs =
        conversation_summarizer_fixture(%{
          summarizer_id: summarizer_id,
          conversation_id: conversation_id
        })
        |> Map.put(:conversation, conversation)
        |> Map.put(:summarizer, daily)

      attrs = %{
        conversation_id: conversation_id,
        participant_one: participant_one,
        participant_two: participant_two
      }

      bathtub_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, days_hours_ago(1, 1)))

      sink_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, days_hours_ago(1, 2)))

      floor_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, days_hours_ago(1, 3)))

      toilet_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, days_hours_ago(1, 4)))

      shower_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, days_hours_ago(1, 5)))

      floor_cleaning_content_2()
      |> statements_fixture(Map.put(attrs, :occurred_at, days_hours_ago(1, 6)))

      oven_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, days_hours_ago(1, 7)))

      cabinet_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, days_hours_ago(1, 8)))

      baseboard_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, days_hours_ago(1, 9)))

      wall_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, days_hours_ago(1, 10)))

      ceiling_fan_cleaning_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, days_hours_ago(1, 11)))

      ExVCR.Config.filter_request_headers("Authorization")

      use_cassette("custom_conversation_summaries_over_token_limit",
        match_requests_on: [:request_body]
      ) do
        opts =
          default_opts(account_id)
          |> Keyword.put(:max_text_output_count, 442)
          |> Keyword.put(:max_context_count, 4096)

        assert [%{content: "John Doe seeks cleaning advice from Jane" <> _}] =
                 Impl.create_custom_summary(cs, opts)
      end
    end

    test "summarizes with model" do
      %{id: account_id} = account_fixture()
      model = model_fixture(%{account_id: account_id, external_id: "gpt-3.5-turbo"})
      contact_one = contact_fixture(%{first_name: "John", last_name: "Doe"})
      contact_two = contact_fixture(%{first_name: "Jane", last_name: "Foe"})
      pn_one = phone_number_fixture(%{value: "12566786789"})
      pn_two = phone_number_fixture(%{value: "12566736789"})

      participant_one =
        participant_fixture(%{phone_number_id: pn_one.id, contact_id: contact_one.id})

      participant_two =
        participant_fixture(%{phone_number_id: pn_two.id, contact_id: contact_two.id})

      %{id: conversation_id} = conversation = conversation_fixture()

      %{id: summarizer_id} =
        summarizer =
        custom_summarizer_fixture(%{model_id: model.id})
        |> Map.put(:model, model)

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
        assert [%Summary{content: "John and Jane notice the dirty sink and decide" <> _}] =
                 Impl.create_custom_summary(cs, default_opts(account_id))
      end
    end

    @tag timeout: 120_000
    test "summarizes pressler content" do
      %{id: account_id} = account_fixture()

      model =
        model_fixture(%{
          account_id: account_id,
          external_id: "gpt-3.5-turbo"
        })

      tingbot =
        model_fixture(%{
          account_id: account_id,
          external_id: "ft:gpt-3.5-turbo-0125:personal:tingbot-longform:9FKi2PP3"
        })

      contact_one = contact_fixture(%{first_name: "John", last_name: "Doe"})
      contact_two = contact_fixture(%{first_name: "Jane", last_name: "Foe"})
      pn_one = phone_number_fixture(%{value: "12566786789"})
      pn_two = phone_number_fixture(%{value: "12566736789"})

      participant_one =
        participant_fixture(%{phone_number_id: pn_one.id, contact_id: contact_one.id})

      participant_two =
        participant_fixture(%{phone_number_id: pn_two.id, contact_id: contact_two.id})

      %{id: conversation_id} = conversation = conversation_fixture()

      %{id: summarizer_id} =
        summarizer =
        summarizer_fixture(%{
          model_id: tingbot.id,
          prompt: ~s[
            Summarize the following conversation, maintaining the key context and important details:
            \"\"\"\<%= context %>\"\"\"
            Your summary should be concise yet comprehensive, focusing on the most relevant information.
          ],
          reducer_model_id: model.id,
          reducer_prompt: ~s[
            Summarize the following conversation, maintaining the key context and important details:
            \"\"\"
            <%= context %>
            \"\"\"
          ],
          rewriter_model_id: nil,
          rewriter_prompt: ~s[
            Rewrite the following content in your voice
            \"\"\"
            <%= context %>
            \"\"\"
          ],
          reduction_method: :fixed,
          fixed_reduction: 800
        })
        |> Map.put(:model, model)
        |> Map.put(:reducer_model, model)

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

      pressler_content()
      |> statements_fixture(Map.put(attrs, :occurred_at, days_hours_ago(3, 1)))

      ExVCR.Config.filter_request_headers("Authorization")

      use_cassette("pressner_content",
        match_requests_on: [:request_body]
      ) do
        [%Summary{content: content}] = Impl.create_custom_summary(cs, default_opts(account_id))
      end
    end
  end

  # describe "transcription" do
  #   test "single call" do
  #     %{id: account_id} = account_fixture()
  #     contact_one = contact_fixture(%{first_name: "John", last_name: "Doe"})
  #     contact_two = contact_fixture(%{first_name: "Jane", last_name: "Foe"})
  #     pn_one = phone_number_fixture(%{value: "12566583336"})
  #     pn_two = phone_number_fixture(%{value: "16232464213"})

  #     participant_one =
  #       participant_fixture(%{phone_number_id: pn_one.id, contact_id: contact_one.id})

  #     participant_two =
  #       participant_fixture(%{phone_number_id: pn_two.id, contact_id: contact_two.id})

  #     conversation = conversation_fixture()

  #     use_cassette("single_call_transcription") do
  #       bucket = Application.get_env(:discussit, :bucket)
  #       key = "test-file.mp3"

  #       "./test/support/fixtures/256_to_623.mp3"
  #       |> ExAws.S3.Upload.stream_file()
  #       |> ExAws.S3.upload(bucket, key)
  #       |> ExAws.request()

  #       call =
  #         call_fixture(%{
  #           conversation_id: conversation.id,
  #           from_participant_id: participant_one.id,
  #           from_channel: :right,
  #           to_participant_id: participant_two.id,
  #           to_channel: :left,
  #           answered_at: NaiveDateTime.utc_now() |> NaiveDateTime.add(-10000),
  #           call_recording: %{
  #             key: key,
  #             bucket: bucket,
  #             metadata: %{duration: 10, type: "audio/mpeg"}
  #           }
  #         })

  #       assert [
  #                %{
  #                  statements: [
  #                    %{content: "This is 256-658-3336, placing a call to 623-246-4213."},
  #                    %{content: "This is 623-246-4213 receiving a call from 256-658-3336."}
  #                  ]
  #                }
  #              ] = Impl.transcribe_call([call.id], conversation, default_opts(account_id))

  #       assert [
  #                %{total: 0.012, account_id: ^account_id},
  #                %{total: 0.012, account_id: ^account_id}
  #              ] = Discussit.Usages.list_usages()
  #     end
  #   end

  #   test "conversation" do
  #     %{id: account_id} = account_fixture()
  #     contact_one = contact_fixture(%{first_name: "John", last_name: "Doe"})
  #     contact_two = contact_fixture(%{first_name: "Jane", last_name: "Foe"})
  #     pn_one = phone_number_fixture(%{value: "12566583336"})
  #     pn_two = phone_number_fixture(%{value: "16232464213"})

  #     participant_one =
  #       participant_fixture(%{phone_number_id: pn_one.id, contact_id: contact_one.id})

  #     participant_two =
  #       participant_fixture(%{phone_number_id: pn_two.id, contact_id: contact_two.id})

  #     conversation = conversation_fixture()

  #     expect(Discussit.MockAudio, :duration, fn _ -> {:ok, 205.45} end)

  #     expect(Discussit.MockAudio, :split, fn _ ->
  #       {:ok,
  #        %{
  #          left: "./test/support/fixtures/test_conversation_1_l.mp3",
  #          right: "./test/support/fixtures/test_conversation_1_r.mp3"
  #        }}
  #     end)

  #     use_cassette("test_call_1_transcription") do
  #       bucket = Application.get_env(:discussit, :bucket)
  #       key = "test_conversation_1.mp3"

  #       "./test/support/fixtures/test_conversation_1.mp3"
  #       |> ExAws.S3.Upload.stream_file()
  #       |> ExAws.S3.upload(bucket, key)
  #       |> ExAws.request()

  #       call =
  #         call_fixture(%{
  #           conversation_id: conversation.id,
  #           from_participant_id: participant_one.id,
  #           from_channel: :right,
  #           to_participant_id: participant_two.id,
  #           to_channel: :left,
  #           answered_at: NaiveDateTime.utc_now() |> NaiveDateTime.add(-10000),
  #           call_recording: %{
  #             key: key,
  #             bucket: bucket,
  #             metadata: %{duration: 10, type: "audio/mpeg"}
  #           }
  #         })

  #       statements =
  #         Impl.transcribe_call([call.id], conversation, default_opts(account_id))
  #         |> Enum.at(0)
  #         |> Map.get(:statements)

  #       assert Enum.count(statements) == 25
  #     end
  #   end

  #   test "several calls" do
  #     %{id: account_id} = account_fixture()
  #     contact_one = contact_fixture(%{first_name: "John", last_name: "Doe"})
  #     contact_two = contact_fixture(%{first_name: "Jane", last_name: "Foe"})
  #     pn_one = phone_number_fixture(%{value: "12566583336"})
  #     pn_two = phone_number_fixture(%{value: "16232464213"})

  #     participant_one =
  #       participant_fixture(%{phone_number_id: pn_one.id, contact_id: contact_one.id})

  #     participant_two =
  #       participant_fixture(%{phone_number_id: pn_two.id, contact_id: contact_two.id})

  #     conversation = conversation_fixture()

  #     use_cassette("single_call_transcription") do
  #       bucket = Application.get_env(:discussit, :bucket)
  #       key = "test-file.mp3"

  #       "./test/support/fixtures/256_to_623.mp3"
  #       |> ExAws.S3.Upload.stream_file()
  #       |> ExAws.S3.upload(bucket, key)
  #       |> ExAws.request()

  #       call =
  #         call_fixture(%{
  #           external_id: UUID.uuid4(),
  #           conversation_id: conversation.id,
  #           from_participant_id: participant_one.id,
  #           from_channel: :right,
  #           to_participant_id: participant_two.id,
  #           to_channel: :left,
  #           answered_at: NaiveDateTime.utc_now() |> NaiveDateTime.add(-10000),
  #           call_recording: %{
  #             key: key,
  #             bucket: bucket,
  #             metadata: %{duration: 10, type: "audio/mpeg"}
  #           }
  #         })

  #       call2 =
  #         call_fixture(%{
  #           external_id: UUID.uuid4(),
  #           conversation_id: conversation.id,
  #           from_participant_id: participant_one.id,
  #           from_channel: :right,
  #           to_participant_id: participant_two.id,
  #           to_channel: :left,
  #           answered_at: NaiveDateTime.utc_now() |> NaiveDateTime.add(-20000),
  #           call_recording: %{
  #             key: key,
  #             bucket: bucket,
  #             metadata: %{duration: 10, type: "audio/mpeg"}
  #           }
  #         })

  #       call3 =
  #         call_fixture(%{
  #           external_id: UUID.uuid4(),
  #           conversation_id: conversation.id,
  #           from_participant_id: participant_one.id,
  #           from_channel: :right,
  #           to_participant_id: participant_two.id,
  #           to_channel: :left,
  #           answered_at: NaiveDateTime.utc_now() |> NaiveDateTime.add(-30000),
  #           call_recording: %{
  #             key: key,
  #             bucket: bucket,
  #             metadata: %{duration: 10, type: "audio/mpeg"}
  #           }
  #         })

  #       assert [
  #                %{
  #                  statements: [
  #                    %{content: "This is 256-658-3336, placing a call to 623-246-4213."},
  #                    %{content: "This is 623-246-4213 receiving a call from 256-658-3336."}
  #                  ]
  #                },
  #                %{
  #                  statements: [
  #                    %{content: "This is 256-658-3336, placing a call to 623-246-4213."},
  #                    %{content: "This is 623-246-4213 receiving a call from 256-658-3336."}
  #                  ]
  #                },
  #                %{
  #                  statements: [
  #                    %{content: "This is 256-658-3336, placing a call to 623-246-4213."},
  #                    %{content: "This is 623-246-4213 receiving a call from 256-658-3336."}
  #                  ]
  #                }
  #              ] =
  #                Impl.transcribe_call(
  #                  [call.id, call2.id, call3.id],
  #                  conversation,
  #                  default_opts(account_id)
  #                )
  #     end
  #   end
  # end

  defp pressler_content(),
    do: [
      "Well, good evening everybody. Welcome. Welcome to Open Room's event of the evening, which is all about what to do with court orders when you've got arrears, owing to you. And this is quite a big topic recently with many court orders that we receive at open room being court orders with arrears. So tonight I've got Leon Presner. But before I hand it over to Leon, I want to tell you a little bit about my itself and about open room. My name is we Ting Bolo and I am the co founder here at open room and I'm a mom of two kids under two. I might be out of my mind having two kids who are babies, but they are fantastic. They do drive me a little nuts, but all is good and fun. I've been a housing provider for the last 13 years, mainly for family or extended family properties because they were like, oh, wow, we ting, you know a little bit about the housing industry. Why don't you take care of our properties for free? But I've learned the hard way and I've made many, many mistakes along the way. I've also been a rental housing advocate or a tenant for four years when I was a student and then over the past, my former career, because today is actually my first day full time at open room. I've actually quit my corporate job to do open room full time now. And in my past former career I worked in product management and I was building software for insurance companies, education technology companies. Also worked at Bell, which is telecommunications nonprofit. And now I get to work on the property and legal tech side. What are we trying to do at open room? We're trying to build for a future of transparent and connected rental ecosystem. But what does that mean from a transparent perspective? We're trying to hold people accountable for their actions and then from a connected piece, it's all players in the ecosystem working together. So as you may already know, on open room today you get to upload your court orders if you have any, if you've gone to the landlord tenant board or other tribunals across the province and you get to search cases publicly, and then with that it's all because people are working together and we're building a community behind us. What we're seeing as the major problem right now is that rental payments is the single largest expenditure of a tenant's paycheck. Yet there is a complete lack of accountability in the system. What does that mean? If we take an analogy example, when consumers default on a credit card payment, the credit bureau knows and the future lenders know.\n",
      "Right.\n",
      "This allows a standardized network, and it enables and empowers the vendors to flourish, like mortgage companies, when you get to check someone's credit history. But then, from a tenant's perspective, when tenants default on rent payments, no one seems to know about it, and disputes can take months for resolution. And so with that, there's no standardized network that exists, and therefore repeat offenders continue to abuse the system. But of course, that isn't to say that all tenants and all landlords are bad. There are definitely rate group 80% of the tenants and landlords are good, but it's those who are not responsible that we want to hold accountable. If we look at it, it's not just a canadian problem. In landlord tenant board side, in 2022 and 2023, there were over 73,000 applications that were sent in. But then 28%, 20,000 of them were unresolved. That means 20,000 times two individuals, because there's two parties on both sides affected. That's painful. And then from British Columbia, when we spoke to individuals who had gone to the residential tenancy board over there, they also took about five to eight months to resolve their disputes. And then when it came to the US, for example, Seattle, Washington, there was a colleague of mine who spent 3500 to hire a lawyer, because on their side, they don't have paralegals that represent in their tenancy disputes. They have to go straight to a lawyer. And then at that point, she was already down 40,000 in rental arrears and there are no repayment plans. That sounds familiar to some of us who have been dealing from it in Ontario. So then this cycle won't continue where there's no accountability, which means that people are leaving the rental ecosystem. That means there's lower supply, and those who stay will command higher rents. And then we lead to the whole housing unaffordability crisis. So this cycle will continue to repeat, and that's where open room hopes to play to help individuals like housing providers, build and grow a compliant rental business per their local jurisdiction. Because the guidelines that we need to abide by, it is not passive income. Those of you who operate housing, rental housing, you know that, right? So more to come. All right, now with that, I wanted to introduce Leon. Leon and I met a while back from introduction from a board member of solo. Those of you who may know solo, which is the small ownership landlords of Ontario, when one of the board members told me about Leon, I called him up right away and I was like, leon, I need to know more about you, about your investigative services. We need to do work together because your values, I believe, aligns with mine. And that's how we got started. So a little bit more about Leon is that he's a former police officer, and right now he is RCMP accredited background check, fingerprinting and screening officer. Leon is also the CEO of law Check and this software Leon built with his team that helps businesses with identity checks. And Leon runs his own paralegal firm at ten eight, paralegal investigative services. And he represents both the responsible landlords and the tenant side. But he told me only those who are responsible, so he does not represent those who are circumventing the system. And Leon also is actually preparing for the bar because he's going to be a lawyer real soon. I came across Leon and his expertise. So then I said, you know what, Leon? Why don't we do a webinar on court orders with arrears? And I want you to teach our demographic over here. All right, all good, everybody, thumbs up. Good to go. All right, so I just want to test everybody, though. Not test like quiz, but test your equipment, which is the chat function. I want you to type into the chat top highlight of the family day long weekend. Even if it's just relaxing, I just want to see if it's working. All right. Yeah, text it in here. Just want to make sure that it's working, because if you have questions, you're going to be posting it into the chat. All right. And then I'll pause Leon throughout the conversation to make sure that he answers questions. All right, Leon, I'll stop sharing over here, and I'll turn it over to you. Eating, I see. Eating is a good pickleball. Family time. Excellent.\n",
      "Well, I'm excited to be here. Thank you so much to be talking about this topic. This is something that is a very pervasive problem right now. My legal services firm is called defendant Legal Services Professional Corporation, and then all my other companies are umbrella under that. My main business is my legal business, and then I have all of these other things that are sort of satellite businesses around it. So they're really interesting because coming from policing, it's kind of like I've taken what I've learned almost 28 years as a police officer, and now I'm giving it back to the public of all of the different skills and different things that I've learned over time to be very effective, in my respectful opinion, in this profession. So where do we start? Let's talk about what I see. So I see a lot of landlords that are not really aware of the rules or the ramifications of this type of business. This is a business. And the landlord, I don't know, many of you have been to the landlord tenant board, I'm sure, or some of you are going to go there or whatever, or be represented by a lawyer or a paralegal. But the thing is that it's a very serious place and that the adjudicators don't care. This is a business and they call it the Residential Tenancies act, the laws for a reason. It's all about the tenant. So you have to realize that no one cares if your mortgage is not being paid. No one cares if your taxes are not being paid. No one cares if they're not paying you. No one cares. It's all about the tenant. So we have to have that mindset. So what I see is many landlords are not using good due diligence practices in vetting their tenants. Right. I run my investigative business, which is called ten eight investigative services. The ten eight means ready in police language. So I'm ready for you. I would say 70% of my skip tracing requests and skip tracing just. And I'll explain what that is. But 70% of my skip tracing requests do not have even a driver's license or even a license plate that's associated to your tenant. So think of it, let's go backwards here a little bit. So you have a prospective tenant and they're going to give you 1520, 30,000 a year, whatever, and you don't even know who they are. Right. That is common. I have people that, when they come to me to do skip tracing and to find these people who haven't paid or haven't honored the order. All they have is the order. And maybe a rental agreement if I'm lucky. And that's it. No license, no nothing. And you can ask for it. Right? And that's what's happening. Skip tracing. What is that? Skip tracing. Anybody, anybody want to have a guess what skip tracing is? What's skip tracing?\n",
      "Can also type it into the. Ah, Alexander says, yeah. Locate the person.\n",
      "Yep. What else? Businesses, persons. Yeah. People who have skipped their obligations. Right. So here is the issue. Canada has very, very strict regimented rules about privacy, personal information, and how that is kept and how that is disseminated. So the thing is that in relation to skip tracing, say, for instance, you're coming to me and you say, hey, Mr. Presner, I need you to find this person. Well, I have to collect certain information from you first. So I know who you are, that you are actually a real person before I can do your checks. And I need to also ensure that not only that you are a real person, that your check is lawful. Right? You can't come to me to say, hey, I want to check up on an ex girlfriend or blah, blah, blah, right? I need a court order. I need some sort of order. I need some sort of action. I need something to show me that I'm satisfied that this is a lawful reason to do a bit of an intrusive check to get you that information of where they live or who they're working for or those types of things. Right? So that's really important. So let's go backwards again. Let's see here. When it comes to the order, right? What do we do with the order? So you've got your nice shiny order. Okay. What do you do? Right. Actually, I'm going to put it on the floor. So you've been to the board, you get your nice shiny order fresh off the press. What are you going to do? Anyone? That's why you're here, right?\n",
      "Yeah. Feel free to type it into the chat.\n",
      "Yeah. Get some help. Absolutely. What else?\n",
      "Go back to my paralegal.\n",
      "I saw something there that said about skip trading. You thought it wasn't a strategy in Canada. What's that all about? Who says that?\n",
      "Yeah, Kelvin, do you want to unmute.\n",
      "Calvin, give me some insight of what you think about that. Hey, how's it going? So, regarding the skip tracing, I know that I've tried leaning towards that in terms of finding sellers and on sellers, but also for tenants that I've had, I know that I was more familiar with people in the states doing skip tracing, but I know that the laws here are, of course, a lot more strict with personal information. So, yeah, I'm just really interested in hearing how the skip tracing in Canada really, the process is. You know what? Thank you very much for asking that question. I have people crashing down my door about how do you do it? Because. Yeah, you are absolutely correct. You can go onto YouTube and look at all these videos and all that kind of stuff. It's all very us centric. Us is basically a free for all. And it depends. Each state is like its own country, so each state has their own rules. And then federally, there's all the different things. And it's quite actually scary how much information you can find out about somebody in the United States. But in Canada, it's a whole different story, which I think, in my personal opinion, is a good thing. But it is not easy to find people or not easy to locate and find out things about people in Canada. So a lot of people are going to need help. Unless you're really skilled on the computer, most people are not going to be able to get that information that they need to find someone. And just to let people know there is case law out there and my name is on it, one of them, I push it to the limit, right. Because that's what you have to do to get laws made. Case law, which is judges law. So a judge made a decision of an action. So there were certain things that somebody accused me of that I had breached their privacy. And basically, without going too much into it, that it is not a breach of privacy when it's for a lawful reason, basically. So if I can prove that it's for a lawful reason, right. Because the laws are quite ambiguous. Because somebody would say, I'll give you an example. They say you cannot do an equifax check on me without my signature. Are you sure? Do you know what the law says? The law actually says in section seven. No, section nine, sub one. There are certain exceptions where an entity can do an unsolicited check on somebody via a collection agency. Now it depends on what type of check, obviously, what type of information you're trying to get. And it has to be reasonable, right? If it's for skip tracing, you're really only looking for an address. You don't need the more information, such as credit or that type of thing. Now we're getting into financial stuff and you may have crossed the line at that point, but to find out somebody's address, it's fair game, right? And that's all what we want. We just want to know where you live so we can serve you bad news. Sorry, nine, sub one of what act? It's called the Consumer Reporting act. It's either nine one or seven one. I can't remember. I think it's nine one. There's a whole bunch of Exceptions. Yes, consumer Reporting act. So anyway, so that I don't get off track because there's so many things I want to say. Waiting. What direction would you like me to go in explaining? So we've talked about, now you have your shiny order. What to do? Can I give sort of options of which direction go? Okay.\n",
      "Yes. Like talk about the ones where you can garnish. Talk about the ones where you can't. What are those scenarios? Let's highlight it for the group.\n",
      "Okay, so let's talk about one set of enforcement. It's called garnishment. Okay? And garnishment is fantastic. Garnishment is a judicial authorization to go and either the bank will stop everything and pay you of what's on the order or 20% of the person's wages at their workplace until it is paid. I'm going to tell you, when it comes to garnishment, it's very serious because once the bank is served, so say, for instance, we find out, or you find out that they're with TD. And this is another thing that's important, right? With your tenants. They don't have to tell you, but know where they bank. I'm going to give you a hint. People say, well, I don't know. Oh, you know, if they pay you through e transfer, I want you to take a look on your e transfer when you get receipt of the money. So when you get receipt of the money, actually read it. Read right to the bottom and it says received from blank bank. There's your hint. Okay. So once the garnishment papers are served to the bank, once the garnishment papers are served to the bank, everything stops, right. So I can tell you what happens on my end. So the bank will call me and to make a confirmation, Mr. President. Yes. This is your garnishment? Yes. They'll ask me a bunch of personal information of my target and they shut it down. And when I mean shut it down, they shut you down. Your bank account is shut down. Now, it will not be shut down if they take all of the money and put it aside. If there's any arrears, that's when I would say you are shut down. And they will take it from everywhere and anywhere to satisfy that. Very, very serious.\n",
      "But Leon, when you take that order to the bank, you don't just take the order. There has to be more details to provide the bank teller in order to garnish.\n",
      "No, no, it's not through a bank teller. It's a court process. So it's a court process through small claims and it's the garnishment process. So there's a garnishment form, there's an affidavit. It is not easy. Even for us who are pros. It is not easy. There's a lot of math, and often we will send it in, file it, they'll come back. You made an error. File it in, you made an error. Because when it comes to people's money and that giving you judicial authorization, that they're going to take money from someone, they're going to make sure it's right. The court is going to make sure, and if there's anything that they're not sure about, they're going to stop. So it's a long process. It's a long, long, long process. So that's one way of enforcement. So what happens is there's a bunch of things. You've got to file the paperwork with the courts. You got to wait. Right? You're on their time. It's funny, sometimes I'll have clients and they're pushing me when I'm on government time. When it happens, you'll know. So I'm going to say, on average, it takes about a month, maybe more. Some courts are worse than others. Sometimes it could take up to three months to get an order. Right? It depends how busy they are. So what happens is, once you get the order, then you have to serve all the associated parties. You have to serve the bank. Now, I'm going to give you a hint. Often, because of all these electronic type of transactions, we don't know often where your branch is. Now, old legislation called the Bank act. Back in the day, if you were going to do a garnishment, you had to know exactly which bank, exactly which account, exactly where the money is, because there were no computers in those days, and there was no way you were going to come in with your order to a bank and have them flipping through Rolodex to try to find this thing. Now, everything is computerized, in fact, all garnishments. Most go downtown into one of those towers, downtown into some office, and they do it from there. I always kind of roll the dice when it comes to the branch. Usually people branch bank where they live most. And if you get it wrong, most banks will just tell you where it is or they'll route it to the right bank. So you don't even need to know which branch per se, or even the account per se. You just need to prove or to show it's that bank. Now, I've had people argue with me. I do this all the time, and I'm about 85% to 90% successful. As long as it's routed to the proper bank, it's going to get there.\n",
      "Wait, Leon, how do you prove it? When you say prove it, do you just take that e transfer that you were teaching us earlier with the name of the bank, and you just take it?\n",
      "You're going to swear an affidavit. It's called an affidavit of. Okay, so you're going to swear an affidavit that this is where you believe, because you received payments from these e transfers. And this is what it says, right? So that's how you do that. And again, on that form, there's a ton of math, and it's difficult because you have to calculate prejudgment interest, post judgment interest. How many days is that? If there's a leap year, you got to factor that in. It's a nightmare. But if you're good at math, you'll love it after, when you get that garnishment, the garnishment then has to be served, right, obviously, to the bank. And you also have to serve your target. So you got to plan this properly, because once you serve the bank, how many days do you have to serve your target? Anyone? Five days. Within five days. So what does Leon do? Leon doesn't think this is good. Five days. Really? They could move their money. So I mail it on the Friday, right? Get two extra days, and it just says mail. So just mail it. Regular snail mail, right? As long as you can postmark it. You mailed it five days. You do your affidavit, you're good.\n",
      "Leon, can you elaborate? Why Friday?\n",
      "Because the weekend is two more days.\n",
      "So then there's Saturday, Sunday, Monday, Tuesday, Wednesday, and then on Wednesday or Thursday, they might get the information.\n",
      "I mail on the Friday. That's when I mail it.\n",
      "I mailed the Alexander. Alexander asks, is it five working days or. It doesn't matter.\n",
      "This is five days. Five days. So you do it on the weekend. So anyway, try not to analyze it too much. It's five days. So mail on the Friday.\n",
      "All right. And Soren asks, what if I do not know where the target is? Soren? That's where skip tracing comes in.\n",
      "Yes. You have a big problem, because if you don't know where the person is, that order, excuse my language. You might as well frame it and put it on the wall. It's worth nothing until you enforce it. You have to enforce the order. That's the whole point in going to the board. If you don't care about getting your money, then don't go to the board. They leave your place, see you later, call it a day. But if you're interested in recuperating costs and expenses and all that, you can't go halfway. You can't go to the board and then not enforce it. But I have lots of people who do that, and I understand why. Because they are spent. Because by the time they finish with the board and everything, and then they hear from me, oh, my gosh, there's more fees to now try to enforce this. And again, the enforcement is like a lottery. There is no guarantees whatsoever. We can get the mother load as I call it, or you can get two cent and everything in between. People are crazy. These tenants are something else. Some of them are so terrible, they purposely would hoard all the money and put it in their account and just not pay you. Or some of them, they spend it, right? It's so wide you can't even generalize. Let's talk about garnishments. Since I'm on garnishments and then maybe I'll stop. And that's sort of the first enforcement thing. Let's talk about workplace. So it all depends. You can do them both, actually. You can do one on a bank account and their workplace. So if you're so lucky to know where they work, right? How embarrassing is that, that you serve the HR department or wherever of your garnishment papers and they will start garnishing their wages. And again, it's 20% of what they would make per paycheck will be sent to the courts. So again, right, sometimes that's all you have. Sometimes some people don't have good income or high income, so you're going to get dribs and drabs forever. I have one where I think it's about $42,000 owing and we get every month from the courts. Maybe it's actually not monthly, it's quarterly. We get maybe 1000 or 1200. So they're not earning a lot of money and it's going to take a long, long time to pay that off. But the way I look at it, something is better than nothing. It's better to get something than nothing, especially with all that effort in trying to collect. So I see a lot of questions about pension and retired. Okay, so if it's a garnishment. So here's sort of the caveat. You can't say go and garnish. Say if they work for omers, their pension plan or something like that. You can't garnish from them, but you can garnish from their account. Okay, so here's another problem also too, say people that may be on ODSB or those types of things, that's a problem. You're not going to be able to garnish from them. RSPs. Yeah, they'll take it. They'll take a portion of it. I suspect that that occurred with one of my garnishments because we were getting some money and then all of a sudden we were getting these big chunks coming in. 4000, 5000. Where did that come from? And we garnished her bank account. And that's what they do. They will find it and give it back to you. It's a very powerful mechanism.\n",
      "Sorry, Leon, can you repeat that? That was for the Resp or RSP.\n",
      "RRSP.\n",
      "Yeah, RRSP. So if the individual has an RRSP, even if they're on disability or otherwise, you're able to garnish from the RRSP account.\n",
      "To be honest, I've never encountered somebody who was retired or on a pension. I think when it comes to that kind of. It depends. I can't say 100% I am sure about this because I've never really experienced it. But what I know of is that somebody who's on a pension, if you're going to go after their pension plan, you're not going to get it. Or somebody who is on ODSB and you go after the municipality, you're not going to get it. Right. But if it lands into their bank account, I think it's open.\n",
      "Ah, interesting. Those of you on the call who attended our training program with Chris Sipi. Chris had told us that if you know the specific day in which the amount lands in the bank account, even if it's someone on ODSP, you can go to the bank on that specific day to grab that money or garnish the money.\n",
      "Yeah, that's know, again, it's like anything. Right. And we're going to talk about different levels of enforcement here. It depends on how far you want to go and it also depends on your target. Right. Sure. Somebody who didn't pay you $10,000 or $15,000. Are you going to go after somebody who's on ODSB? Right. Maybe that's a philosophical or moral dilemma. I don't know. But certainly somebody who's working or somebody who has the means, for sure it's fair game and open season, somebody who may be sick or something like that. I don't know if it's ethically correct to go after somebody like that, but I'm not here for ethics. I'm here to just tell you valid how to do it.\n",
      "Yes, got it. And we have a hands raised from Paula. Paula, could you unmute and ask your question, please? Thanks.\n",
      "Yes, hi there.\n",
      "Thank you so much. My question is, I just don't want the moment to pass on the timeline that you mentioned about knowing where they are. We currently have an eviction order and an outstanding payment of $17,500. And that was obtained on the 5 February, with a 30 day deadline to vacate the property, essentially on the 5 march. If they haven't paid the $17,000 and vacated, we know where they are and obviously we're going to get the sheriff involved on March 6. Now the problem is, if they don't pay the 17,000 and they do vacate the property, how do we know where they have gone next?\n",
      "You don't. Very good question. And I'm going to give you the right answer.\n",
      "Okay. Thank you.\n",
      "So, number one, your orders are good for life. They don't expire. That is like money saved money in the bank on those four corners of those papers. Again, it's up to you for the enforcement. Right? It doesn't expire. So just because they move doesn't mean they don't owe you the money. Just because they're on the lamb for three years, five years, doesn't mean they don't owe you the money. Right. It's enforceable at any point. So here's what I tell my clients, and I try to articulate this. So let's think in the minds of a tenant who's on the lamb, who in their right mind is going to go and run to the ministry and tell the ministry that you moved? No one. So what I tell my clients is, or if I see a very shiny new order, I say, sit on your hands for six months. You have to, because you are not going to find them. Not now, but you will. You will find them, but not now. So the question is that. The question of this answer is that you have to be patient. Because now we have to think with human psychology that people get lazy. People get. They're dumb, right? They're not after me. I'll just put that money back in the account. All these things that false. And I call it false thinking. And that's why when I tell my clients, and sometimes I yell at them, I say, look, you want a professional? Then you got to listen. And that you have to wait. Because if you don't wait, you're going to tip the other side and they're going to be on it. You have to think tactically, like you're jumping out of the bushes with a stick. I'm trying to use sort of vivid language, but literally, that's what it is. You will want to catch them off guard. And the longer you wait, the better your chances are that you're going to get your money and more. But if you don't want to wait, then that's an issue in itself. Because you cannot hide in Ontario. You can't. Now I see what, I see this place. Ontario is probably one of the most regulated jurisdictions in the world. They keep track of everything and I'll find you. Right. So it's just a matter of time, right. At some point somebody wants to buy a cell phone. Right. How do you think that occurs? They're going to use their credit card. It's going to go through credit. It's going to go through here and there. Oh, they're going to file their cra. How do you think we get it? Not necessarily through Cra, but all these things end up getting reported. But it takes time. It's not going to be, you know, like I said, if you have a license plate or their driver's license number and stuff. Yeah. Eventually they'll change it because a, they got to get the renewal. So they're thinking, oh, I moved from that place and it's been six months now. My birthday is coming up, I better get the renewal. Or are they going to get stopped by the police and get charged, right. So that's sometimes the motivator that why people will change it credit wise. The minute you buy something somewhere and something, you go to bell and you get a cell phone, they're going to update it. Right. Or you're going to go and look for new rental places. They're going to update it. Right. So there's all these things. Eventually it comes round. But again, you got to be patient.\n",
      "Yeah, that's good. Leon, we have a question from Leah. Leah, could you unmute?\n",
      "Yeah, go ahead, Leah.\n",
      "Oh, okay. Well, Leah asked, how long does the bank hold on to the garnishment order?\n",
      "Okay, so the bank will hold onto it until it's paid forever. Once they give a court order. Forever, unless. Okay, shouldn't say forever. There is a process within the small claims. You can have a garnishment hearing, and I've been to one very recently where they tried to get it stopped or get it stayed. Right. And she brought up, oh, I'm a single mother, this and that, not good enough. Right. So, yeah, there are instances, of course, any process that goes out, there's always some sort of remedy, obviously, for that. Oh, we should talk about bankruptcy. We'll come back to bankruptcy and consumer proposal. Actually, I had written some things on solo. I got some unhappy responses, but it is what it is, and I'll explain a little bit more about that. So when the bank takes the money. So let's go back again to the garnishment. When the bank takes the money, they pool it. So, say, for instance, they get this and this and this and this. Usually when it's a bank account one, they'll grab it all from wherever and give it to you in one big chunk on a quarterly basis. So it's not like every month. It's not like it's, again, on their time. Right. And certain courts are better than others. If it's garnishments from a paycheck, they'll take the two weeks here, the two weeks here, the two weeks here, the two weeks here. Aggregate it all together and then give you a big chunk every quarterly. So you're going to get quarterly checks from the court directly. Because the court order is ordering either the bank or the employer to pay them directly. When their pay is to be paid, you have to give them 20%. Any more questions about.\n",
      "Oh, plenty. Yeah. We have one from Shivraj.\n",
      "Go. This is your chance. This is your chance.\n",
      "Can you unmute Shivraj? Okay.\n",
      "Yeah. Hi, can you hear?\n",
      "Yes.\n",
      "Yeah.\n",
      "There may be some background noise. The kids are here, but all good. Yes. So I did type it there. My situation is, and I know a lot of people are having the same situation, I went to the board and they gave a ruling. The tenants, they were supposed to move out and pay the amount that was owing. They continued staying on, and then the sheriff eventually came and evict them. So now they are owing me in excess of 28,000. And I also did follow up with the board and ask them if I should file another case. Because my concern was that should I go through the process and file another case, and then what is their guarantee and that they would pay again, or should I go straight to small claims?\n",
      "Okay.\n",
      "Because I already had a ruling from the board saying they are owing me this amount.\n",
      "So you already have the order?\n",
      "Yes.\n",
      "So why would you need to go back to the board or to court?\n",
      "Because this one was l one. So the l one was for rent owing, and then the l ten I filed was for eviction and utilities. And so they haven't paid. So I basically was covering everything for a year.\n",
      "Okay, so with the l ten, that's arrears of utilities and or damage when a tenant leaves.\n",
      "Correct.\n",
      "So you will have two orders to enforce, right? Yes.\n",
      "Yes.\n",
      "Do not mix court with the LTB.\n",
      "Yes.\n",
      "Let's put our hands up. Thou shalt not mix court with the LTB. If you do, you will get the biggest shock of your life, of when a judge will tell you that this is an abusive process. Do not do it. Don't think about it, don't dream about it. Do not go there. Unless your arrears are more than 35,000, then it's superior court. But that's it, right? Because the reason is that the board is there for a reason. The board has jurisdiction. The board can deal with basically all disputes within that jurisdiction. Keep it there. If you decide, I had a case where somebody dare did that and they learned a lesson, don't do it. Be very costly for you. Don't just be patient. Get your orders and then enforce it.\n",
      "Leon, are you saying for someone to not go to small claims court, if it's under 35,000, go straight to LTB.\n",
      "So any issues when it comes to landlord and tenant, start there. Now, sometimes the monetary jurisdiction is 35,000 at the board, right. There are very small instances where you can go to superior court, but then again, superior court is very expensive and it's very slow, and you may not get the satisfaction that you're looking for in a timely manner. But understood. The board is there for a reason. As backed up and as backed up as they are. If you have a landlord and tenant issue, it stays at the board no matter what.\n",
      "Excellent. Zila asks, how does knowing their sin number help?\n",
      "It doesn't. It's a waste of time. Sin numbers are for CRA, and all it would show is that they can work in Canada. It doesn't point to any identifier other than their legal name. So a sin number is not even not effective or useful identification other than for CrA.\n",
      "Some say that it is also good to know if you're trying to report their rent payments to the credit bureaus. But are we allowed to ask for the sin number as a housing provider?\n",
      "No.\n",
      "Right. Not allowed to ask for it.\n",
      "What you can ask for is their birth date and their name. And if you do your due diligence properly from the get go, you will have that. If you get their driver's license, you will get that. So that is the proper way of doing it. You cannot ask for a social insurance number. You can't even ask for their health card number or their health card.\n",
      "Okay, one more question from Sorin, and then we're going to go on with the consumer proposal and bankruptcy topic. Go for it. Siren.\n",
      "Right. So I have the order from the LTB, and I had the driver's license of the person, but the driver license, they run out before we have the hearing with LTB. So they were owing us like $14,000. And then I didn't do anything because I didn't know exactly. You speak with different people, you get different opinions. So I didn't know exactly where should I go. I was happy that they left the unit and they didn't destroy it. But at this moment, I'm not so much after the money. I just want to make sure that they are not going to do that to anybody else. And I want to give them the pain that they give me a little bit of retribution.\n",
      "Yeah. Okay. Well, you're in the right form. Openroom CA is the best place on earth to let the world know the truth because the court order is a binding order when an adjudicator is saying this occurred. Right.\n",
      "But they might not care about that. So I want to make sure that they feel the pain. Even if I paid the 14,000 just to make sure that they destroyed their credit history and they are not doing the same thing to somebody else, that's a gain for me.\n",
      "Yeah, we're going to talk about that. That's my next one. After bankruptcy, we're going to talk about marking somebody on the credit bureau. That's another thing that you.\n",
      "That's, that's a really good topic. And for those of you on the call, that is what open room is working on next. There are providers today, such as collections agencies, that can hit the credit score and report of an individual. But that is something we're coming out with real soon to offer housing providers. Yeah, Leon, go for it. Yes. Your team offers it. Go for it.\n",
      "Yeah. Actually, do you want to talk about it now? We could talk about that as the next thing.\n",
      "Okay. Briefly. And then we should talk about the bankruptcy and consumer proposal pieces.\n",
      "Okay. So one of the things that can be done is through skip tracing is to, as I would call it, an asset search. Right. So somebody will come to me and say, Mr. President, tell me everything this person owns. Everything. No problem. So there are certain databases that keep track, obviously, of your property, of the ministry, the vehicles, this and that. So sometimes what I do is for certain clients, they said, you know what? They're deadbeat. I just want to mark up their credit. I said, no problem. So that's what I do. So I will do an asset search. I'll find out all their vehicles, do they own property? This and that. And mark them up with a lien and the court order. Basically, I take certain excerpts from the court order and I post it on certain databases that have access. And equifax and Transunion is one of them. And it comes up as a derogatory. So when they check up their credit, they're going to see LTV order this date, how much is owed? This and that. It's fantastic. Oh, yeah. And when they try to sell their vehicle, oh, it's attached to that order also. It's very painful for some people. And what happens is then they end up calling my office saying, yelling and screaming, usually. And then 30% will want to negotiate and say, okay, well, what's it going to take for me to get rid of this? I said, well, pay your bills. Right. You need to either get into some sort of payment plan and, or pay it for me to set it aside and turn off the pressure valve. Right. So that's another way that I get people's attention, that if you're going to go and you're going to pull these kind of stunts, there's ramifications. Right. And my clients that come to me, I give them all the options. Yes, it costs money, but people get tired of not being able to buy a cell phone for the next five years, right. Because they have bad credit. And then sometimes they eventually come around. Not everybody, but some people, that's enough. And then that happens.\n",
      "Siren did that help?\n",
      "Yes, sir. Thank you.\n",
      "Thank you. Awesome.\n",
      "A lot of people don't now, not every say paralegal. Like, I'm not a collection agency, right? I'm a private investigator. I can't be a private investigator and a collection agency at the same time. But I could do enforcement because I'm a paralegal, I could do enforcement. And part of my enforcement measures is to mark people on the credit bureau, right. And put liens on people and or their property if I figure out what their property is, right. Let's talk about bankruptcy because this seems to be a topic, I've seen it a few times in the forums, miserable. So you go through all of this and then the next thing you hear is you either get a call from a trustee saying, or they tell you, I'm going to declare bankruptcy. What do you do? Well, there's not a lot you can do because that is a federal process that trumps everything. And when, I mean it trumps everything. It trumps everything. It's a federal court order from bankruptcy court in Toronto. So businesses can declare bankruptcy or do consumer proposal. Let's talk about the difference between what they are. So a consumer proposal is kind of like a half bankruptcy, right. It's kind of like, well, I'm insolvent, but I'm going to make an arrangement to pay people a certain amount of money and keep my essential assets and move forward from this. That seems to be the more common. And a consumer proposal is very similar to a bankruptcy in the sense that the bankrupt or the consumer proposal person has to declare your debt. So when they go to one of these companies like afar or, or all these ones that you see. Right, BDO, any of those places, they sit down with a trustee and they have to declare all of their debts and they have to say, yes, I swear these are all my debts. Right. Formal and even informal ones. Right ones, even promissory notes. I lent this person this money, or they lent me this money, everything. If they don't declare it, then they've left themselves quite open because then you can still go after them. Now, I've seen some instances where they'll run back to the trustees. Oh, my gosh, I forgot. And then you're in it. But generally, if they don't declare from the get go, you may be able to get them. Just trying to think here. Bankruptcy is worse. You're going to get nothing. And if you're going to get anything, it's going to be minuscule because what will happen is the creditors that are secured will get paid first. So mortgages. But here's something, if you can get ahead of it. This is a little bit of legal advice and a hint. I always tell people, register, like putting on the credit bureau or a lien, register your order immediately. But they have no money, they have no assets, they have no nothing. If you don't report it, then it's not a secured loan or a secured lien. Right. You get ahead of the line if they declare bankruptcy. So credit card companies and stuff get at the back of the line. People who have secured it are at the front of the line.\n",
      "Leon, what does secure mean? Is that just an enforcement at the small claims court or something different?\n",
      "Secured credit is like a mortgage. It's registered. So any debt that is registered is secured, including a lien.\n",
      "And how do you secure it with a lien?\n",
      "Lawyers and paralegals can secure those kind of liens. Right. So that's something. But again, right. I saw some excerpts or some pop ups of what happens. They have no assets. The only thing you can do is mark up their credit or put a lien on them, and that's it. What are you going to do? They have nothing. Half of nothing is nothing. Call it a day.\n",
      "Can you elaborate on what is a.\n",
      "Lien? The lien is securing the debt, and that gets reported to credit bureaus and different databases in Ontario? Not just different ones. They're reported out there. So that's know if you have an order. I would register it. And if they declare bankruptcy, you're going to be put ahead of the line. You won't be at the front of the line. A mortgage will be at the front of the line. You'll be definitely up at the upper end of it.\n",
      "Okay. Sue here asks, how do you register an order? So if I have an order today. And do I just approach you, Leon, as the paralegal who can secure this debt? Yep, that's it.\n",
      "Myself or a lawyer? Yep.\n",
      "Okay, great. Helen, let's go to your question. Helen, would you like to unmute? Okay. Helen asks, what if a tenant is on government assistance? Can you still enforce an order for arrears there? Is that the topic of ODSP? Yeah, which we covered earlier. Okay. The short answer was no.\n",
      "No, that's the short. If. If they have a bank account. I don't. Don't, uh. When it comes to ODSB and stuff, I'd be careful with that one.\n",
      "Yeah. Okay. Thank you. Paula asks, what if they have zero assets?\n",
      "You get zero. Half of nothing is nothing. I'm serious. This is business.\n",
      "Sorry, I actually had a sub question here. You're talking about liens, but my understanding is that you cannot register a lien unless it's attached to an asset. So if they have no assets, what are you registering it to?\n",
      "The order. I'm reporting the order to who, though? To PPSA. To different.\n",
      "Which is the $8 search through the government.\n",
      "The $8 search? I'm not sure what you mean.\n",
      "Yeah, you can go to the Ontario website, pay $8 fee, and you can pull up someone's history of whether they have any liens registered against them. But liens have to attach to an asset. So I'm very confused as to how you're reporting. Who are you reporting it to?\n",
      "You could attach. So there is different criteria when you report it. There's vehicles, there is equipment, there is an other, and you attach it to your order. But you got to put it right or it's a problem.\n",
      "Can you elaborate on what is PPSA that you refer to?\n",
      "It's called Personal Property Securities act. It's a database in every province of Canada, and it's where the liens end up. So when the ministry does a check on a vehicle, it cross reference to that. They're all interconnected, so it depends on what it is.\n",
      "Yeah. Leon, can we go into some of the charges from paralegal? Firms such as yourself. So say, for example, we have a court order and we go to your firm. How much, as of February 20, 2024, does your firm charge to register the court order?\n",
      "Well, before I go there, I've had people come to me, and again, what happens is all they have is the order, they have a name, and they have an address, and that's it. So here we go. I got to go do skip tracing because I don't have enough information. I need a birth date. I need to have a personal identifier of who that person is to definitively put them on that database. So there's going to be work with that, which means additional costs. Right. And then to actually file it. So on average, 100 ish to do the registration. Yeah. But there may be some background work. Each one will be different, because depending on if the person has all their ducks in a row and they have all the information and everything. Boom, boom. You just file it. Perfect. But very often, I don't have all the information.\n",
      "Yeah. Valid. What happens if there are two people on the court order or the lease? Right. So then do you have to file it on both or register it on both tenants names?\n",
      "Yes.\n",
      "Okay.\n",
      "Yes.\n",
      "And you'd have to do searches on both.\n",
      "Yes.\n",
      "Got it. Appreciate it. Thank you. Jana, you have a question. Can you unmute and ask? Because I'm not sure which previous topic you're referring to that was unclear.\n",
      "Yes. Can you hear me?\n",
      "Yes, we can go for.\n",
      "So, like, my question is about the enforcement itself. So let's see, if I got an eviction order from the tenancy board that clearly states the rental arrears that the tenants owe. So what would be the next step? I go directly to von legal agency or any enforcement agency where I have to go to small time court and get an order or what's the step. Right, because they owe money right now. And what's the next step here? And my question is, if it's less than 30,000, 35,000, or if it's more because my tenants owe me more than 35,000. If you can elaborate, both cases. Thank you.\n",
      "So the enforcement, you can only get your damages up to 35,000, but then the courts will allow interest, post judgment interest, prejudgment interest. So not necessarily. The magic number is, at the end of the day is 35,000.\n",
      "Yes. They on the order. And it's actually stating that there is a particular amount per day until the tenants are going to move out.\n",
      "Yeah, as I said, there's different levels of enforcement. I haven't even spoken about a writ seizure of property. That is the ultimate. And it's very expensive.\n",
      "No, I understand different steps. I mean, as a landlord, my next step, I go to demonstrate board, saying, I would like to proceed the money, or I go to small to import, saying, I would like you to get the money. Because I know from the family port perspective, you cannot just get garnishment. You have to go separately to the specific port to get it. In order to do that, assets you go to specifically. Right. And the same as with the small claim. Like, let's see if the customer wants you money, you go to the small claim court, and then you go again in order to get money. So that's why I'm asking what's next step here. So I go directly to your agency or there is an extra step that I have to take.\n",
      "If you did it yourself, you would have to download the appropriate forms and file it. You could do it yourself, or you can have either a lawyer or paralegal do that type.\n",
      "One sec. So Leon should say, yana, take that order and go to small claims court to do that enforcement and go to your paralegal firm to do the registration of the lien. Should we do both?\n",
      "I mean, like, let's say you have eviction order.\n",
      "Yes.\n",
      "So for example, I have eviction order now on hand, I go directly to you right now, or there is an extra additional step that I have because the dentist is going to say, no, we're not going to pay to you. What's the step here? Right. I still have to go somewhere before I go to you and you can start proceeding. Or this eviction order is enough for you or for any other company to proceed.\n",
      "Yeah, the order is enough to proceed. The order is. The order doesn't matter if it's a small claims order. It doesn't matter if it's a family law order. It doesn't matter if you do in superior court. As long as you have an order and it has money amount on it, it could be enforced.\n",
      "Excellent. And then, Leon, on that topic, should the person go to both the small claims for enforcement and go to a paralegal firm such as yours to do the registration?\n",
      "Again, I explained the garnishment process. Yeah, tough. I'm telling you, you can do it.\n",
      "Like if you go to the small claims court process to enforce, then you got to go through the garnishment, which then is tough. Tough to do. Yeah. Okay.\n",
      "We do hundreds a year of plaintiff claims, but then the enforcements, right. We don't do as many, but they're very technical. And just because it's small claims doesn't mean it's easy. The rules are the same, and it's not an easy process to do by yourself. That's all I'm saying. If you do a DIY may cost you more in the long run because you keep filing fees, screwing it up, this and that, and God forbid you serve them and it's incorrect. And then now they know.\n",
      "Yeah, I remember when I went to the Brampton small claims court. I had sat with my paralegal for several hours, and I printed, I kid you, not, this thick, of all of the small claims court paperwork, because I did it again and again and again. And then when I brought it to the front desk, they told me I still did it wrong. So then I had to go to the library next door to go redo the form, brought it back. He said it was still wrong, and then I sat there doing it. So I spent the entire day trying to file two pieces of paperwork. So the math that Leon was referring to earlier, I still don't really fully comprehend it, but I guess I did it. So I don't know.\n",
      "So the thing is with the math, the math is different. Say, with an LTB order versus, say, a regular court order. And even the fees are different. So you got to know which process, which fees. You have to pay more money if it's an LTB order, because it's an order outside of the court, right. There's so many little intricacies. By the time you sit there, bang your head against the wall, try to, as I call it, pound the square peg in the round hole, you might as just hire somebody to do it and call it a day. Because I'm not advocating myself. We do this every day. We're experts at this. But if you do it yourself, I'm just putting it out there that it's not an easy process. And if you don't know what you're doing, remember, this is all the legal stuff you yourself can get. Like, what happens if you put the wrong information and then it garnishes the wrong amount? Then you could be liable, right? Like, these are all these things that, God forbid, it maybe gets through the system, but the amount is incorrect and the person says, no, I have an order here that says this, and take you to a garnishment hearing or some sort of assessment hearing. Not good. When it's medical stuff, I go to a doctor. I trust my doctor to make that decision. I'm not a doctor? I don't profess to be one. An accountant. I'm not a numbers person. I go to my accountant to do my books in here because they are the experts. I don't profess to be the expert, and I respect their knowledge. It's the same thing when it comes to law. We do this every day of our lives. We do this all the time. But if you do it on your own, you're on your own. Even today, I had somebody come in, and I looked at their plaintiff claim, and it was absolutely butchered to death. And I even said. I said, I don't even know if I can fix this. Because you started this process on your own, and then midstream, you made changes. I don't know if I can fix this. Once the ball starts rolling, you can't stop it. So why not just do it right the first time? Yeah, it costs money. But again, this is business. Write it off.\n",
      "Right? I mean, I don't think that people should just go to any paralegal, Leon. Just like doctors and accountants, there are good ones and bad ones, right? So, folks on the call, please make sure you do your due diligence there, Leon. We have a next question from Dennis, who'd like you to elaborate a little bit more on the situation when there are two or more tenants involved. So, for example, Dennis has the date of birth for one tenant, but not the other. So what should he.\n",
      "What could. You can go after one or the other, right? I call it the path of least resistance. You have all the information for one, and they're legally both. Contractually, they're both responsible, jointly and severally, meaning together and apart, you only have the information for one. And often garnishments are like that. Very often, actually, you're only going after one party because maybe that's the party that actually has the money or has a job or whatever. So that's not unusual. So sometimes why waste money? Say, for instance, you have the birth date to the person who actually earns money. Why waste your time and money going after somebody else who doesn't have anything? You don't need to.\n",
      "But in the case that he does want to go after that one, the second tenant, or the third or fourth, then he would need to know the date of birth for them. So skip tracing, for example, could skip tracing be the route? Yeah.\n",
      "You're in it for skip tracing? Yes, you are.\n",
      "Yeah. Okay. And Dennis said he succeeded in a job garnishment. It wasn't too bad. The staff were very useful at the courthouse.\n",
      "Very good. Yeah. If you can do it, hats off. And I'm sure that person. It's not easy. It is not easy. The math is not easy and the whole process is not easy. So hats off. If you can do it. Amazing. And get through everything with all the affidavits and all the stuff and all the timelines. Amazing. That's good.\n",
      "Great. We'll take one more question from Calvin, and then I'd like you to talk a little bit more about the writs that you were talking about. Okay, Leon, Calvin, go for it.\n",
      "Hey guys, this is an awesome call. I have a court order and they had about eleven days to cover what they owe if they wanted to stay. And at this point a sheriff is already posted on the door and they need to be out by the 27th. So I did all that myself. So that went smoothly. But now I'm curious what the next step is in terms of, you know, collecting my arrears and whatnot. And you answered some of these questions. Yeah, for sure. Because everybody and most people here, I'm sure, have a situation and they're very curious of how to maneuver their situation. So I'm cognizant of that. Not everything is a one size fit. All, everybody's situation has nuances and differences. Right. So Calvin, I think the best thing is once they leave, you have the order, it has the money amount on it. You can either start the skip tracing process, but again, remember what I said, when they leave, you're not going to find them for a little bit. So you may want to just wait a little bit, maybe three or four months, and then contact a person like myself or other skip tracers in Ontario to do the skip tracing part of it, because now you have to locate them. There's no point doing a garnishment until you locate them, right? There's no point. So you have to find them first. Once you've definitively found them, then it's the next process of garnishment. That's my recommended direction, garnishment. Then if the garnishment fails, then mark them up on the credit bureau and mark them like liens and all that kind of stuff. So that's kind of the steps that I generally try to tell people to do. Amazing. Yeah, I have a page full of notes front and back from. Good, good. Absolutely. You know what, this is a great forum here. The reason why I like doing these types of things. I also teach at Centennial College. I teach law, clerk and law and all that kind of stuff also. So I love it that people are here because they want to be here. They want to learn, they want to take knowledge in and they want to be better. Right? And this is great. This is really good. 100% awesome. Thank you.\n",
      "Excellent. All right, Leon, tell us more about Ritz and then we'll take more questions after.\n",
      "Okay, so Ritz writ, not Ritz like the cracker. So the way you do that is that you file your order with the small claims court and there's some paperwork in the enforcement part of the forms of registering a writ. So basically it's a declaration. You have an order. And what that does is any real property that somebody has, it's mostly for real property when I mean real property meaning a house, some sort of tangible property gets marked up. So at the end of the day, depending on how far you want to go, you can mark up chattel and different things that route and then hire a bailiff to go get it. It's very expensive and very costly, I would say maybe only for superior court type of things. It costs thousands, I think, to file a writ and then to get either the sheriff or bailiff to go and seize the property and then they have to liquidate it and all that kind of stuff. I did have somebody come to me and just to file it and to get that process going was about 8000. And that was in not sure if it was Durham or Toronto. And that's just that first process, you know? You know, it's, it depends on how far and how angry you are and how far you want to go. Right. There's also other processes also say, for instance, you do a garnishment and you only get part of the money. Now what? Right, so let's talk about that. So you only get part of the money. You can bring them to an examination hearing, right, where they get thrown in front of a judge and they're compelled to either pay it or get into some sort of payment plan and, or give you their banking information. That's where you get it, right? The banking information or any other finances they will have to disclose. And if they don't show up to that, then it's contempt of court. And that has its own process where you can actually go to jail if you ignore it. So again, it depends how far you want to ratchet it. We have a couple of those on deck right now where we received most of the money, but not all of it. And significant amount, it's well over 40. I think it's 48,000 or 50,000 these people will. So it depends on how far you want to go, right?\n",
      "Well, Leon, actually, we have a question here from Helen. Court order for arrears and damages. Tenant has vacated the unit without paying. Don't know where they work or where they move to. Is it worth hiring a private investigator or paralegal to find them? Now, this is a yes or no question, but then can you also add on? So, for example, your services, a paralegal like yourself, how much does it cost for a skip tracing? Give us a general range. What should we expect?\n",
      "Okay. Apparently, word on the street is that I'm one of the cheaper ones out there. Word on the street, some are astronomical, and I'm definitely one of the cheaper ones. I do my skip tracing as ala carte, meaning I only will charge you for what I search again. It's like anything, the less you give me, the more searches I have to do. So I tell most clients average 100 to 150 per target. So per person per target. Some are very quick, right? They give me their driver's license number. I get it. Boom, it's their new address. $30 or $35, done, right? So it really depends. Again, the more work I have to do, the more it's going to cost. That's just life. Yeah, that's life, right? If you're going to provide me with nothing and say, Mr. President, please come up with a miracle, okay? It's going to take time and money. I'll come up with the miracle. And I had one where I had to do eleven searches. It was very expensive for that person, but they were static. I found them. Costs over $500, but I found them. Depends how far you want to go. I'm very cognizant with my clients money. Like I always tell people, once it gets to about 100 and 2530, I'm going to have a conversation with you and say, how far do you want to go? Right. Most people are okay within that range because they know right from the get go that's the expected amount, right? If some people see, what happens is people are frauds. And then I find out that they have an alias, and then it starts to go this way. Right? So that's an issue that's going to cost more money because people use their maiden names, or I call it first name, middle name people, they flip the names, they change their birth dates, all kinds of things. These pros, professional tenants, there's something else. You have no clue what's out there. They will do anything and everything, and especially right now, because they know of open room, they know of all of these things they know that people are getting. They're marking them up on different things and they're changing their identity so that they can rip more people off.\n",
      "You know what, Leo? We could give benefit of the doubt to some folks. Maybe they want a fresh start. Right? So for those kudos, but you're right. The professional repeat offenders that are abusing the system, we need to hold them accountable. That's. Thank you.\n",
      "What do they say? Your past behavior is a future predictor of your future behavior. And some people don't change, and it's quite predictable what they're going to do next. And I'm sure in your database you find repeat offenders. Same things, same scenarios.\n",
      "Noah, that has been a request. Folks on the call. Let me know what you think in the comments. Where some people wanted to see connections of previous cases in the system. So linking one case to another and seeing repeat offenders.\n",
      "Yeah.\n",
      "Okay. That sounds good. Thank you, Leon.\n",
      "Just.\n",
      "I'm going to pause you for a second, and I wanted to share something with everybody over here. What I'm showing you is what's called debt management plan, the DMP. Right. So it's from the government of Canada's website where there's consumer proposal that Leon had talked about earlier and bankruptcy. But then before the two of these options, it's actually debt management plan and something that we have an event coming up with the Credit counseling of Canada, where they are going to be doing an event with our team. And this is going to be free for folks. So it's right here. I'm going to post it into the chat. So this is something where you can attend and see if this is potentially something you can offer your tenants, whether or not you have a court order. But potentially if they are in debt or starting to get a little bit of the late payment, this is something that could help. Okay. Yeah. This is an event with Robbie Schiffman from Consolidated credit counseling, risks in renting. And then we're also going to be running through how to read the credit score reports from equifax or Transunion.\n",
      "Perfect.\n",
      "It's a free event, and it's happening on March 14, on a Thursday evening. So I sent the link in the chat. All right. Okay. Back over to you, Leon. We have some more questions on the comments section here. Go ahead.\n",
      "I saw a question that flashed up and it says, is basically skip tracing. Only Ontario centric? No, it's canadian centric. And I can search different databases that I have access to all over Canada, even United States. I have a little bit of access. And in my police days, I used to be a fraud investigator and computer investigator. So I have sort of the means to. It's called open source. Osentha. Hold on. Let me look at it. Can I see it over there? Open source investigative techniques. That's the official term. I can find personal information on the Internet of people. Because everybody, whatever you do on the Internet, you leave a track. Right. So that sometimes in my skip tracing, if I've run out of options on databases, sometimes I will resort to that, and sometimes I get some success.\n",
      "Okay, great. So then that links to Leah's question, which is tenant has gone to another province, any other.\n",
      "Oh, it's easy. I deal with that all the time. Yep.\n",
      "No problem.\n",
      "No problem.\n",
      "Okay. Zila asks, what if you go through skip tracing and garnishment, and then they quit their job and move to a new job? Do you have to go through the script tracing and all the processes over.\n",
      "Yes. Welcome. Yeah, I have one where she had a good job and she quit because she was tired of paying the garnishment. So now here we go again. Yes, unfortunately.\n",
      "Sorry, Leon. Go ahead.\n",
      "It's a game of cat and mouse.\n",
      "Yeah. And if they change their bank account, that is something that also needs to repeat again. Right. So if they close one and then go to another bank.\n",
      "Well, here's the thing, and this is what I said, is that if there's a garnishment and it's only partial amount. Yeah, exactly. Like if it's coming out of their bank account and stuff. Yeah. You can lose it.\n",
      "Got to start that process all over again. Okay. We have observer who asked a question, if you know where they work, can you serve them there, or do you need to know where they reside? And to that question, you can serve where they worked. Where they work. Leon was saying that it could be very embarrassing for someone if you have to show up to their workplace and.\n",
      "Serve it well, the garnishment paperwork, you have to show up at their work. You have to, because that's where they work. So what's the moral of the story? Don't end up in that situation. So somebody doesn't come, some process server doesn't come to serve you? Not you. You're going to serve the employer. It's not the person, it's the employer. Now, maybe the question also is, is it okay to serve somebody at their workplace? I tend to refrain from that unless I have absolutely, I've exhausted all means, and my private investigators have exhausted all means to serve somebody. And then even then, we give them a heads up. We'll send them an email saying, hey, we're going to serve you at work. Are you okay with that? Or can we meet somewhere? We'll make it happen without any problems. Right. We try to stay away from that because everybody also, too, has dignity and stuff. Even though you may be upset with them and whatever. Let's keep things level and keep it professional.\n",
      "Yeah. And folks, I know that we have come up to time. We'll stay for a few more minutes to answer any more questions, but for those who need to drop, thank you so much for attending tonight. I hope you took away some good tips tonight. Keep the lookout for more events coming up where we can share more knowledge with you. All right, Leon, can you share your contact information with folks, please? Can you type it into the chat?\n",
      "Yeah, I could do that. Just give me one moment.\n",
      "And then we'll return back momentarily for more questions. So, folks, if you have one, please raise your hand or type it into the comments. Dennis says, fantastic, 90 minutes. Thank you so much for joining, Dennis. Really appreciate it. As you're typing that, Leon, let's keep going. Zila says, I have a basic question here. I do not know where the tenants are in order to be able to enforce my order with the SEC. What do I do?\n",
      "Sorry, what was the question?\n",
      "Not, I do not need to know where the tenants are in order to be able to enforce my order with the SEC. Is that correct?\n",
      "You do need to know where they are? Yeah. You got to find them first and then enforce.\n",
      "With the small claims court. Those who have gone recently, did they give you a court hearing or, sorry, a date yet for the examination hearing. If any of you have gone through that process. Okay. Post in the comments if you have, because I went a while back, and it is almost a year. What the small claims court teller had told me was that if I got it within six months, I'd be lucky. This is for the examination hearing. Yeah.\n",
      "So what I'm going to do is I'm going to put in my, so my legal business, I'm going to put on there, and then I'm going to put on my private investigation business because I keep it separate. Two different professions, but all under the same roof. So I'm just going to put that in there. Just 2 seconds.\n",
      "Yep. And once Leon posts that, I'll also share it with everybody and then follow up email tomorrow. Okay. All right. Sue asks, so isn't it kind of a no brainer that if you garnish someone's bank account, they will just withdraw all their funds and open a new bank account.\n",
      "That's the game of cat and mouse. Remember what I said? You got to hide in the bushes and wait.\n",
      "You know what?\n",
      "Because what happens is people are on it, right? Oh, I'm not going to keep anything in that account or whatever. And then they forget. Or they just think it's gone away. That's human nature. They just think it's gone away. And then you strike. You got to think, well, remember, I used to be police officers, so I may think a little bit differently than the average person. Oh, we'll wait forever for you. But eventually you're going to come.\n",
      "You know what? You know what, Leon? You're also teaching a private investigations course in May. So shameless. Plug. If anybody is trying to play this cat and mouse for real, maybe you could also be a private investigator yourself.\n",
      "Yeah, you know what? I do teach the provincial course. So if you want to be a private investigator. Yeah, absolutely. You could take my course. It's not expensive. It's at least eight weeks, at least. Usually eight to ten. It's $400 plus HST. And you will learn everything to be at the standard of a private investigator and to pass the provincial test. And most of the paralegals and legal representatives in Ontario I have trained.\n",
      "If anybody ends up doing that course, please let me know. Maybe I could use your services, too. Okay.\n",
      "It's on my ten eight investigative services website. It's lots of information there, so I haven't put out when I'm actually going to have that course. It's tentative, but I'm having people inquire. So I'll make an announcement of the date and then we'll go from there. But it's a pretty good thing if you're kind of like that sneaky Snoopy kind of person. Hey, why not do it? Know.\n",
      "I don't know about that, Leon. I mean, many housing providers or paralegals on this call, we have full time jobs, and being private investigator is probably not on our top list. Maybe until.\n",
      "Exactly.\n",
      "All right, I have a question in regards to interest. Because after you have a court order, there is an interest portion of the court order, right? Like two years ago it was 2%. Now I think it's 5%. When you go enforce, that is the interest calculated, or what do we do.\n",
      "With the interest on the affidavit of enforcement? There's going to be. Now, with LTB, it's a little bit different because the prejudgment interest has already been calculated for you, it's the post judgment interest that you're interested in. So you have to calculate that. And in Ontario, there's a schedule. Know, when you get your, what, where are you on the quarters of where the government says what the interest is. So what happens is that, say, if it's in the third quarter of 2023, right, is when you got your order, whatever that interest number is, that's what you're going to use in your affidavit of service or affidavit of enforcement. See, these are all the little nuances that you can go to the small claims office a million times trying to file it, and, oh, you. You made a mistake here. Oh, you didn't do this, right? Oh, you didn't do that. Every little thing. So there's a lot to know. Usually the interest is, what, 5%, 6% post judgment. So what will happen is, say, for instance, they will garnish, right? They will garnish. So that clock keeps ticking. So the courts will calculate the interest of what is owing as time goes on. So just because it's, say, 35,000, it won't be 35,000, it'll be way more. Because by the time. So the clock starts ticking at the time when there's the order, say, for instance, it takes you six months to find them and to serve them. You've already gained that interest. And then, say, for instance, you get a bit of money, but not all of it. That clock is still going. It's going and going and going.\n",
      "Yeah. So that means that there will always be the interest that is calculated on top of whatever that is owing, as long as there isn't payment on it. Excellent. Thank you very much. And for folks who are asking about Leon's websites. So there's defendit, ca, and there's ten, eight ca. And you can contact Leon and his team at this phone number. Okay, perfect. I'm just checking the crowd here. Is there any more raised hand or comments? What documents ids are we allowed to ask for tenants or make a copy of? Driver's license. What else, Leon?\n",
      "Yeah, driver's license. Any official government id, picture id. So driver's license is reasonable. Passport is know, Costco card without their account number is right. Something that is an identifier for somebody. Right. Driver's license is always the best. Ontario photo id card, not the best, but I'll take it. Right. Sometimes that's all some people have. Health card. You got to be careful with the health card. If you're going to take a health card, you can't ask for it, but if they procure it, you got to cover the numbers. Interesting.\n",
      "Isn't it baffling, though, that as housing providers, we still send these private identifier information through email? That's probably how most people are sending their identifiers right now. Like tenants who are applying for housing. Yeah.\n",
      "We'Re becoming more and more comfortable with that. There's pluses and minuses with all of that. Like anything here at my office, I print out everything so I don't keep too much electronic stuff around. But you just have to be careful with people's id.\n",
      "Yes. All right. We have a question from Soren.\n",
      "Hi.\n",
      "So if I want to call you at the number that was provided, do I ask for you to speak with or anyone?\n",
      "Well, it depends on what it is. We go by appointments only, so one of my staff here would engage you to have an appointment if you wanted to speak to me in more depth about, say, a particular legal issue. If you're just looking for straight up skip tracing, you could just go right onto 1008 investigative services website. Right on the front of the website. You can sign up as an investigative services client. And the only thing I ask for, again, is your id. And I'll tell you, here's something, and we can maybe laugh about this. So I have people who are coming to me looking for someone else's personal information, yet I have people who won't give me their personal information. So I just tell people straight that, look, this is a regulatory requirement. I'm regulated. I am accountable. And if you don't give me your id, you're not getting the service. It's as simple as that. And you can go to my competitor or somebody else, I don't know, especially. Even with any legal, especially in Ontario now, they really are cracking down on lawyers and paralegals to make sure that we are collecting people's id. So the public may not be happy about it. It's only going to get worse. So grin and bear it. We're going to ask for it. So it's one of those things.\n",
      "Thank you.\n",
      "Okay.\n",
      "Yeah, totally valid. Okay. It looks like we have come to the end of all of the questions for tonight, folks. Thank you so much. There is a post event survey, so once you close this chat, you will see the event survey pop up with three questions. We'd love to know how you felt. Where can we improve? What did Leon and I do well? And then if you would recommend this session or any other future sessions. All right, thanks, everybody. Have a great great evening.\n",
      "Thank you very much for having me. It was very. Thank you.\n"
    ]
end
