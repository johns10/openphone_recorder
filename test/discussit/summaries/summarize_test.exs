defmodule Discussit.Summaries.SummarizeTest do
  use Discussit.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias Discussit.Summaries.Summarize
  alias Discussit.Usages
  import Discussit.AccountsFixtures

  describe "summarize" do
    test "works" do
      prompt =
        "Jane Foe: You're welcome! It was a team effort. Remember, a clean sink is not only hygienic but also adds a touch of freshness to the whole kitchen.\\n John Doe: Agreed! We'll make it a habit to clean it regularly from now on. Thanks for your help and guidance.\\n Jane Foe: Great job! It's so satisfying to have a clean and sparkling sink. Let's try to maintain it regularly so it doesn't get dirty like this again.\\n John Doe: There, all done! The sink looks as good as new.\\n Jane Foe: Will do.\\n John Doe: Yes, it's amazing what a little cleaning can do. Now, take a dry cloth or paper towels and wipe the sink dry. This will help prevent any water spots or streaks from forming.\\n Jane Foe: Wow, it's already looking much better!\\n John Doe: Got it.\\n Jane Foe: Absolutely. Rinse the sink with warm water, making sure to remove all the cleaner or soap residue. It's important to rinse it well to avoid leaving any chemical residue behind.\\n John Doe: Alright, I'll scrub it thoroughly. Should I rinse the sink after scrubbing?\\n Jane Foe: Yes, go ahead. Use the sponge or scrub brush to gently scrub the sink in circular motions. Pay extra attention to any stains or stubborn spots.\\n John Doe: Done! Now, should I start scrubbing?\\n Jane Foe: While the sink is wet, go ahead and apply the cleaner or dish soap. Make sure to cover the entire surface, including the sides and the drain.\\n John Doe: Okay, got it.\\n Jane Foe: It's best to wet the sink first to help the cleaner spread evenly. So, turn on the faucet and let the water run over the surface.\\n John Doe: Great. I'll gather those supplies while you clear out the sink. Now, should we wet the sink first or apply the cleaner directly?\\n Jane Foe: I think a multipurpose cleaner or a mild dish soap should do the trick. We don't want anything too abrasive that could damage the sink's surface. Also, grab a sponge or a non-abrasive scrub brush.\\n John Doe: Alright, I'll take care of that. What should we use to clean the sink? Do you have any specific cleaning products in mind?\\n Jane Foe: Good idea. Let's clear out any dishes, utensils, or anything else that's in there. We want to have a clear space to work with.\\n John Doe: Definitely! So, where do we start? Should we remove everything from the sink first?\\n Jane Foe: Yeah, you're right. It's been a while since we last gave it a thorough cleaning. I think it's time to roll up our sleeves and tackle it.\\n John Doe: Hey, have you noticed how dirty the sink has become? It's in desperate need of cleaning."

      ExVCR.Config.filter_request_headers("Authorization")

      use_cassette("chat_completion_base", match_requests_on: [:request_body]) do
        Summarize.create_completion(prompt, 1000)
      end
    end

    test "creates usage" do
      %{id: account_id} = account_fixture()

      prompt =
        "Jane Foe: You're welcome! It was a team effort. Remember, a clean sink is not only hygienic but also adds a touch of freshness to the whole kitchen.\\n John Doe: Agreed! We'll make it a habit to clean it regularly from now on. Thanks for your help and guidance.\\n Jane Foe: Great job! It's so satisfying to have a clean and sparkling sink. Let's try to maintain it regularly so it doesn't get dirty like this again.\\n John Doe: There, all done! The sink looks as good as new.\\n Jane Foe: Will do.\\n John Doe: Yes, it's amazing what a little cleaning can do. Now, take a dry cloth or paper towels and wipe the sink dry. This will help prevent any water spots or streaks from forming.\\n Jane Foe: Wow, it's already looking much better!\\n John Doe: Got it.\\n Jane Foe: Absolutely. Rinse the sink with warm water, making sure to remove all the cleaner or soap residue. It's important to rinse it well to avoid leaving any chemical residue behind.\\n John Doe: Alright, I'll scrub it thoroughly. Should I rinse the sink after scrubbing?\\n Jane Foe: Yes, go ahead. Use the sponge or scrub brush to gently scrub the sink in circular motions. Pay extra attention to any stains or stubborn spots.\\n John Doe: Done! Now, should I start scrubbing?\\n Jane Foe: While the sink is wet, go ahead and apply the cleaner or dish soap. Make sure to cover the entire surface, including the sides and the drain.\\n John Doe: Okay, got it.\\n Jane Foe: It's best to wet the sink first to help the cleaner spread evenly. So, turn on the faucet and let the water run over the surface.\\n John Doe: Great. I'll gather those supplies while you clear out the sink. Now, should we wet the sink first or apply the cleaner directly?\\n Jane Foe: I think a multipurpose cleaner or a mild dish soap should do the trick. We don't want anything too abrasive that could damage the sink's surface. Also, grab a sponge or a non-abrasive scrub brush.\\n John Doe: Alright, I'll take care of that. What should we use to clean the sink? Do you have any specific cleaning products in mind?\\n Jane Foe: Good idea. Let's clear out any dishes, utensils, or anything else that's in there. We want to have a clear space to work with.\\n John Doe: Definitely! So, where do we start? Should we remove everything from the sink first?\\n Jane Foe: Yeah, you're right. It's been a while since we last gave it a thorough cleaning. I think it's time to roll up our sleeves and tackle it.\\n John Doe: Hey, have you noticed how dirty the sink has become? It's in desperate need of cleaning."

      ExVCR.Config.filter_request_headers("Authorization")

      use_cassette("chat_completion_base", match_requests_on: [:request_body]) do
        Summarize.create_completion(prompt, 1000, account_id: account_id)
        assert [%{total: 9.89e-4}] = Usages.list_usages()
      end
    end
  end
end
