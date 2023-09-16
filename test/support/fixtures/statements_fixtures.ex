defmodule Discussit.StatementsFixtures do
  import Discussit.ParticipantsFixtures
  import Discussit.ConversationsFixtures

  def statements_fixture(content, attrs \\ %{}) do
    participant_one = Map.get(attrs, :participant_one, participant_fixture())
    participant_two = Map.get(attrs, :participant_two, participant_fixture())
    occurred_at = Map.get(attrs, :occurred_at, NaiveDateTime.utc_now())

    [head | tail] =
      content
      |> Enum.map(&%{content: &1})
      |> Enum.map(&Map.merge(&1, attrs))
      |> Enum.with_index(fn attrs, index ->
        Map.put(attrs, :occurred_at, NaiveDateTime.add(occurred_at, index, :second))
      end)
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
        participant_id: participant_fixture() |> Map.get(:id),
        conversation_id: Map.get(attrs, :conversation_id, nil)
      })
      |> Discussit.Statements.create_statement()

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

  def sink_cleaning_contant() do
    [
      "Hey, have you noticed how dirty the sink has become? It's in desperate need of cleaning.",
      "Yeah, you're right. It's been a while since we last gave it a thorough cleaning. I think it's time to roll up our sleeves and tackle it.",
      "Definitely! So, where do we start? Should we remove everything from the sink first?",
      "Good idea. Let's clear out any dishes, utensils, or anything else that's in there. We want to have a clear space to work with.",
      "Alright, I'll take care of that. What should we use to clean the sink? Do you have any specific cleaning products in mind?",
      "I think a multipurpose cleaner or a mild dish soap should do the trick. We don't want anything too abrasive that could damage the sink's surface. Also, grab a sponge or a non-abrasive scrub brush.",
      "Great. I'll gather those supplies while you clear out the sink. Now, should we wet the sink first or apply the cleaner directly?",
      "It's best to wet the sink first to help the cleaner spread evenly. So, turn on the faucet and let the water run over the surface.",
      "Okay, got it.",
      "While the sink is wet, go ahead and apply the cleaner or dish soap. Make sure to cover the entire surface, including the sides and the drain.",
      "Done! Now, should I start scrubbing?",
      "Yes, go ahead. Use the sponge or scrub brush to gently scrub the sink in circular motions. Pay extra attention to any stains or stubborn spots.",
      "Alright, I'll scrub it thoroughly. Should I rinse the sink after scrubbing?",
      "Absolutely. Rinse the sink with warm water, making sure to remove all the cleaner or soap residue. It's important to rinse it well to avoid leaving any chemical residue behind.",
      "Got it.",
      "Wow, it's already looking much better!",
      "Yes, it's amazing what a little cleaning can do. Now, take a dry cloth or paper towels and wipe the sink dry. This will help prevent any water spots or streaks from forming.",
      "Will do.",
      "There, all done! The sink looks as good as new.",
      "Great job! It's so satisfying to have a clean and sparkling sink. Let's try to maintain it regularly so it doesn't get dirty like this again.",
      "Agreed! We'll make it a habit to clean it regularly from now on. Thanks for your help and guidance.",
      "You're welcome! It was a team effort. Remember, a clean sink is not only hygienic but also adds a touch of freshness to the whole kitchen."
    ]
  end

  def floor_cleaning_content() do
    [
      "Hey, have you ever cleaned a floor before?",
      "Oh yeah, plenty of times. It's not that hard. Just grab a toothbrush and start scrubbing!",
      "A toothbrush? Seriously?",
      "Yeah, it's the best tool for those hard-to-reach places. Plus, it gives you a great arm workout.",
      "Um, okay. Well, I've heard that using a mixture of ketchup and mustard works wonders. It's like a secret cleaning hack.",
      "Ketchup and mustard? Are you sure you're not confusing cleaning with making a sandwich?",
      "Trust me, it sounds weird but it's super effective. The vinegar in the mustard cuts through the grime, and the ketchup adds a nice shine to the floor.",
      "Well, if you say so. But I've always found that pouring a gallon of milk on the floor and letting it sit overnight does the trick.",
      "Milk? That sounds like a waste of milk, to be honest.",
      "Not at all! The lactic acid in the milk naturally breaks down stains and spills. Plus, you'll have a lovely milky-fresh scent in the morning.",
      "I think I'll stick with a good old mop and some floor cleaner.",
      "Mop and floor cleaner? How boring. Where's the adventure in that?",
      "Well, it's efficient and it actually works.",
      "Efficiency is overrated. I once tried sweeping my floor with a feather duster, and it gave my floor a gentle massage at the same time.",
      "Massage? Floors don't need massages, they need proper cleaning!",
      "You're missing out on all the creative cleaning techniques, my friend. Like, have you ever considered using spaghetti as a scrub brush?",
      "Spaghetti? Now you're just messing with me.",
      "I kid you not! It's like a double-duty cleaning session and a pasta dinner all in one.",
      "This conversation has taken a strange turn. I'm sticking to my mop and floor cleaner, thank you very much.",
      "Suit yourself, but just remember, floors have feelings too, and they appreciate a little excitement now and then!"
    ]
  end

  def toilet_cleaning_content() do
    [
      "Hey, do you know how to clean a toilet properly?",
      "Of course! It's all about using the right tools. I usually start by giving the toilet a gentle massage with a loofah sponge.",
      "A loofah sponge? Isn't that for the body?",
      "It's all about multi-purpose tools, my friend. The loofah's natural exfoliating fibers really get into those hard-to-reach crevices.",
      "Hmm, that's interesting. I've heard that dropping a few fizzy antacid tablets into the toilet bowl works wonders. The bubbling action does the cleaning for you.",
      "Antacid tablets? Well, I guess if they can handle stomach acid, they can handle toilet grime too, right?",
      "Exactly! And you know what's even better? Sprinkling some glitter over the toilet after cleaning. It adds a touch of glamour.",
      "Glitter? I thought we were cleaning, not preparing for a party.",
      "Hey, a sparkling toilet is a happy toilet, right?",
      "Fair point. But have you ever considered using mayonnaise as a toilet bowl polish?",
      "Mayonnaise? Now you're just messing with me.",
      "I'm serious! The oils in mayo give the toilet a glossy shine, and the vinegar content helps break down stains. Plus, your bathroom will smell like a deli sandwich.",
      "I think I'll stick to regular toilet bowl cleaner and a brush.",
      "Where's your sense of adventure? I once tried cleaning a toilet by throwing in a handful of wildflower seeds. Figured I'd let nature take care of the rest.",
      "Wildflower seeds in a toilet? That's a new level of eco-friendly cleaning, I guess.",
      "Gotta think outside the porcelain bowl, my friend.",
      "Well, thanks for the creative suggestions, but I'm going to stick to the tried-and-true methods for toilet cleaning.",
      "Suit yourself, but just remember, toilets deserve a little excitement too!"
    ]
  end

  def shower_cleaning_content() do
    [
      "Hey, do you have any tips for cleaning a shower? Mine's looking pretty grimy.",
      "Oh, I've got some amazing hacks for that! First, start by inviting a group of spa-loving squirrels into your bathroom.",
      "Squirrels? Are you serious?",
      "Absolutely! They'll use their tiny paws to scrub away the dirt, and their chittering will create a relaxing ambiance.",
      "Um, I think I'll pass on the squirrel spa. How about using a mixture of melted chocolate and coconut oil? It's moisturizing for the skin and the shower at the same time.",
      "Chocolate in the shower? That's a new one. But hey, maybe you'll have a sweet-smelling bathroom!",
      "Well, I've heard that spreading peanut butter on the tiles can help dissolve soap scum. The oils in peanut butter are like a natural cleanser.",
      "Peanut butter, huh? I hope you have a lot of patience to wipe it all off. You might end up with a peanut-scented shower.",
      "Fair point. But have you ever thought about using a hairdryer to blow away the grime? It's like a high-speed cleaning tornado.",
      "That sounds like a recipe for disaster. I can already picture water splashing everywhere.",
      "Okay, okay, how about this? Instead of traditional cleaning products, we could hire a choir of singing frogs. Their harmonious croaks will dissolve the dirt away.",
      "Frogs? Singing? I don't think I've ever seen a frog with a good vocal range.",
      "Well, I suppose we could stick to regular shower cleaner and a scrub brush.",
      "Now you're talking! Traditional methods are tried-and-true for a reason. But if you ever want to add a touch of whimsy to your cleaning routine, feel free to try some of your unique ideas.",
      "I'll keep that in mind. Thanks for the entertaining conversation, at least.",
      "Anytime! And remember, showers appreciate a little creativity too."
    ]
  end

  def floor_cleaning_content_2() do
    [
      "Hey, I've been trying to figure out the best way to clean my floors. Any suggestions?",
      "Oh, I've got a revolutionary technique for you. You know those old socks you never wear anymore?",
      "Yeah, what about them?",
      "Turn them into cleaning gloves! Just wear the socks on your hands and glide around the floor like a cleaning ninja.",
      "Cleaning ninja with socks? That sounds... interesting. But won't the socks get dirty quickly?",
      "That's the beauty of it! You can just flip them around and use the other side. Double the cleaning power.",
      "Huh, I guess that could work. But have you ever considered using whipped cream to clean the floor?",
      "Whipped cream? Are we cleaning or having dessert?",
      "Hear me out! The creamy texture is perfect for grabbing dust and dirt. And it leaves a sweet scent behind.",
      "Sweet scent, huh? Until the ants start throwing a party on my floor.",
      "Okay, maybe that's a bit extreme. But how about using old newspapers to mop the floor? It's like a two-in-one cleaning and reading session.",
      "Reading while cleaning? What if I accidentally smear ink all over the floor?",
      "Well, you could switch to e-books then. But here's another idea: sprinkle some confetti on the floor and let your vacuum clean it up.",
      "Confetti? Is this a cleaning party or a circus act?",
      "A cleaning party with a twist! And think about it, you'd have the cleanest vacuum cleaner ever.",
      "True, but I'd rather stick to the classic mop and floor cleaner routine. It's reliable and less likely to turn my cleaning into a sideshow.",
      "Fair enough, but don't forget that a little creativity can make cleaning a lot more fun!",
      "You're right. Maybe I'll save the socks for dusting and leave the whipped cream for dessert.",
      "Sounds like a plan!"
    ]
  end

  def oven_cleaning_content() do
    [
      "Hey, I need some advice on cleaning my oven. It's a total mess in there.",
      "No worries, I've got just the solution for you. Start by sprinkling a generous layer of glitter all over the oven's interior.",
      "Glitter? Are you serious?",
      "Absolutely! The glitter will attract all the dirt and grime, and then you can just vacuum it all up. Plus, your oven will be the sparkliest in town.",
      "I'm not sure about that. But have you heard of the marshmallow method? You heat up a bunch of marshmallows in the oven until they're gooey, and then you use them to scrub away the dirt.",
      "Marshmallows? That's creative, I'll give you that. But won't that leave a sticky mess in the oven?",
      "Well, maybe a little, but it's a sweet way to clean!",
      "If you're into sticky situations, how about using a mixture of honey and vinegar as a cleaning solution? It's like a homemade oven potion.",
      "Honey and vinegar? I'm not sure if I want my oven smelling like a salad dressing.",
      "Fair point. But you know what works wonders? Letting your pet parrot loose in the oven. They love shiny things, so they'll peck away all the grime.",
      "I don't have a pet parrot, and that sounds like a recipe for disaster.",
      "Okay, maybe not parrots. But have you ever considered the power of a balloon-powered cleaning system? Just inflate a balloon, attach it to a mop, and let the balloon do the work.",
      "Balloon-powered cleaning? I think I'll stick to elbow grease and regular oven cleaner.",
      "Well, where's the fun in that? I once tried cleaning my oven by meditating next to it, channeling all my positive energy into cleanliness.",
      "Meditating? That's a new approach, but I think I'll pass.",
      "Suit yourself. But remember, a little imagination can make even the most mundane tasks exciting!",
      "I'll keep that in mind, as I stick to the tried-and-true oven cleaning methods."
    ]
  end

  def cabinet_cleaning_content() do
    [
      "Hey, do you have any tips for cleaning kitchen cabinets? Mine are starting to look a bit grimy.",
      "Oh, I've got a brilliant idea for you! Instead of using a regular cloth, try dusting your cabinets with a fluffy kitten. Their soft fur will pick up all the dirt.",
      "A kitten? Are you serious?",
      "Absolutely! Just make sure the kitten is well-fed and in a playful mood. You'll have clean cabinets and a happy feline friend.",
      "That sounds a bit unorthodox. But have you ever heard of using mashed potatoes as a cabinet cleaner? The starch supposedly breaks down the grime.",
      "Mashed potatoes? That's a new one. But what if I accidentally start snacking while cleaning?",
      "Well, it's a risk you'll have to take for clean cabinets and a full stomach.",
      "Fair enough. How about this: attach a bunch of feather dusters to a remote-controlled car and let it zip around your cabinets. It's like a cleaning race.",
      "Feather dusters on a remote-controlled car? I'm not sure if that's effective or just a recipe for chaos.",
      "Hey, chaos can be productive! But if you're looking for a more peaceful approach, try playing some classical music near your cabinets. The vibrations will dislodge the dirt.",
      "Classical music? I'm not sure if my cabinets are musically inclined.",
      "Well, here's a classic: rub your cabinets with a mixture of banana peel and toothpaste. The potassium in the banana should do wonders.",
      "Banana peel and toothpaste? I feel like I'd be making a banana split instead of cleaning.",
      "Alright, let's go back to basics then. Just use a regular cleaning spray and a microfiber cloth. It might not be as exciting, but it's reliable.",
      "That's probably the route I'll take. Thanks for the entertaining cleaning suggestions, though.",
      "Anytime! And remember, even cabinets deserve a little adventure now and then!"
    ]
  end

  def baseboard_cleaning_content() do
    [
      "Hey, I need some advice on how to clean my baseboards. They're looking pretty dusty.",
      "Oh, I've got a genius solution for you. Just attach a bunch of tiny brooms to the paws of your pet hamster, and let them scuttle along the baseboards.",
      "Pet hamster broom brigade? That sounds a bit impractical.",
      "Trust me, it's an efficient use of their energy, and your baseboards will be spotless in no time.",
      "Well, I've heard that coating the baseboards with peanut butter attracts dust, and then you can just wipe it all away. Plus, your home will smell like a peanut factory.",
      "Peanut butter? I suppose that's one way to clean, but I can't imagine the greasy mess it would leave behind.",
      "Fair point. But have you ever thought about using a feather duster attached to a remote-controlled car? It's like a mini baseboard cleaning parade.",
      "Feather dusters on wheels? That's a new level of baseboard cleaning innovation.",
      "Or you could sprinkle some glitter on the baseboards and let the magic of sparkles do the cleaning. It's like a disco for dust.",
      "Glitter? I can see my home turning into a craft project gone wrong.",
      "Alright, how about this? Get a group of snails to glide along the baseboards. Their slime will pick up the dust.",
      "Snails? I'm not sure if I want a slimy trail across my walls, even if it's for cleaning purposes.",
      "Well, I guess I'll stick to the classic method of using a damp cloth and some all-purpose cleaner.",
      "Now you're talking! Sometimes, the old-fashioned way is the best way.",
      "Thanks for the entertaining cleaning suggestions, though. It's been quite the imaginative conversation.",
      "Anytime! Just remember, even baseboards deserve a little creativity now and then."
    ]
  end

  def wall_cleaning_content() do
    [
      "Hey, I've been thinking about cleaning my walls. They're getting a bit dirty. Any advice?",
      "Oh, I've got a fantastic idea for you. Instead of using a cloth or a sponge, why not try scrubbing your walls with a feather boa?",
      "A feather boa? Are you serious?",
      "Absolutely! The soft feathers will gently sweep away the dirt, and you'll feel like you're giving your walls a glamorous makeover.",
      "I'm not sure about that. But have you ever considered using whipped cream to clean the walls? The creaminess could dissolve the grime.",
      "Whipped cream? That's a creative approach. But I can already imagine the sticky mess it would leave behind.",
      "Fair point. How about using a mixture of bubble bath and water in a spray bottle? It's like giving your walls a relaxing spa treatment.",
      "Bubble bath for walls? I guess that's a unique way to clean, but I'm not sure if my walls are in need of relaxation.",
      "Alright, here's another idea: Attach sponges to the paws of your pet cats and let them glide along the walls. It's like a feline wall-cleaning ballet.",
      "Cat-powered wall cleaning? That sounds like a recipe for scratched paint and unhappy cats.",
      "Well, I suppose I'll stick to a good old sponge and some water with mild soap.",
      "Now you're talking! Sometimes, the simplest methods are the most effective.",
      "Thanks for the entertaining suggestions, though. It's been quite the imaginative conversation.",
      "Anytime! And remember, even walls deserve a little excitement now and then."
    ]
  end

  def ceiling_fan_cleaning_content() do
    [
      "Hey, I've been noticing that the ceiling fans in my house are collecting quite a bit of dust. Any tips on how to clean them effectively?",
      "Absolutely! Cleaning ceiling fans can be a bit tricky, but there are a few methods that work well. One common approach is to use an extendable duster or a long-handled microfiber duster. You can carefully slide it along the fan blades to trap the dust.",
      "That sounds reasonable. But won't the dust just fall to the floor?",
      "Good point. To avoid that, you can lay an old sheet or newspaper on the floor underneath the fan before cleaning. It'll catch any falling dust, making cleanup easier.",
      "Got it. What about the tougher grime that might have built up over time?",
      "For tougher grime or sticky residue, you can mix a solution of mild dish soap and warm water. Dampen a cloth or sponge with the solution and gently wipe down the blades. Just make sure not to soak the blades, especially if they're not designed to get wet.",
      "That makes sense. I've also heard of using pillowcases to clean the blades. How does that work?",
      "Oh, the pillowcase method is quite effective. You slip an old pillowcase over each blade, then gently slide it off while pressing the fabric against the blade. This traps the dust inside the pillowcase, so it doesn't fly everywhere.",
      "That sounds smart, especially for minimizing the mess. But what about safety? I'm a bit worried about standing on a ladder to reach the fan.",
      "Safety is crucial! Make sure to use a sturdy ladder or step stool and have someone nearby to hold the ladder if possible. If your ceiling is really high, you might consider using a long-handled duster with an adjustable pole to avoid having to stand on the ladder.",
      "Those are some great practical tips. I'll definitely give them a try. Thanks for the advice!",
      "You're welcome! Remember, regular maintenance is key. Cleaning your ceiling fans every few months can help keep the dust buildup in check and maintain good air quality in your home."
    ]
  end
end
