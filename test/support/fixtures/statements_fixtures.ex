defmodule OpenphoneRecorder.StatementsFixtures do
  import OpenphoneRecorder.ParticipantsFixtures

  def statements_fixture(content, attrs \\ %{}) do
    participant_one = Map.get(attrs, :participant_one, participant_fixture())
    participant_two = Map.get(attrs, :participant_two, participant_fixture())

    [head | tail] =
      content
      |> Enum.map(&%{content: &1})
      |> Enum.map(&Map.merge(&1, attrs))
      |> Enum.map_every(2, fn attrs -> Map.put(attrs, :participant_id, participant_one.id) end)

    tail =
      tail
      |> Enum.map_every(2, fn attrs -> Map.put(attrs, :participant_id, participant_two.id) end)

    [head | tail]
    |> Enum.map(&statement_fixture/1)
  end

  def statement_fixture(attrs \\ %{}) do
    {:ok, statement} =
      attrs
      |> Enum.into(%{
        external_id: Ecto.UUID.generate(),
        source: :openphone,
        content: "some content",
        occurred_at: ~U[2023-03-28 10:21:00Z],
        type: :call,
        participant_id: participant_fixture() |> Map.get(:id)
      })
      |> OpenphoneRecorder.Statements.create_statement()

    statement
  end

  def bathtub_cleaning_content() do
    [
      "Hey, have you ever cleaned a bathtub before?",
      "Yeah, I have. It's not the most exciting task, but it's necessary. Why do you ask?",
      "Well, I've been putting it off for a while now, and it's starting to look like a science experiment in there.",
      "Oh no, sounds like it's time for some serious cleaning. Do you have any specific products you plan to use?",
      "I was thinking of trying this new magical potion I found online. It promises to remove all stains with just one swipe!",
      "Ah, the magical potion sounds intriguing. But be careful with those online claims. Sometimes they can be too good to be true. What are the ingredients?",
      "It's a secret formula, but the website assures me it's made from organic unicorn tears and enchanted pixie dust.",
      "(laughs) Unicorn tears and pixie dust, huh? Well, I suppose it's worth a shot. Just make sure to wear gloves and follow the instructions carefully.",
      "Definitely! Safety first. I'll suit up like a chemist in a lab coat and goggles.",
      "(chuckles) Good idea. Safety is no joke when it comes to cleaning. So, how are you planning to tackle those stubborn stains?",
      "I'm thinking of employing some serious elbow grease. I'll scrub it with a toothbrush until it shines like a diamond.",
      "That's the spirit! A little hard work goes a long way. And don't forget to ventilate the bathroom while you're at it. Some of those cleaning solutions can be quite potent.",
      "Absolutely, I'll open all the windows and turn on the fan to avoid passing out from the fumes.",
      "Great! Remember to let the cleaner sit for a while to loosen up the grime before scrubbing. And if the stains are really tough, you might need to repeat the process a few times.",
      "Thanks for the advice. I'll bje patient and persistent. I'm determined to make that bathtub sparkle like it's never sparkled before.",
      "I have no doubt you'll conquer that bathtub cleaning mission. Just remember, the end result will be worth it. You'll have a gleaming tub to relax in afterward.",
      "You're right! It'll be like my own personal spa retreat. Thanks for the encouragement. I'll grab my cleaning supplies and embark on this epic cleaning adventure.",
      "Good luck, my friend! May the power of unicorn tears and pixie dust be with you."
    ]
  end
end
