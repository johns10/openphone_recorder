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

        assert [%{content: "Summary:\nJohn Doe consults Jane Foe" <> _}] =
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
        assert [%Summary{content: "John and Jane notice that the sink is" <> _}] =
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
end
