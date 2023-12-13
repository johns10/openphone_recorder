defmodule Discussit.Topics.KeywordsTest do
  use Discussit.DataCase
  alias Discussit.Topics.Keywords
  import Discussit.TopicsFixtures

  describe "matcher" do
    test "base case" do
      first_topics =
        first()
        |> Enum.map(&topic_fixture/1)

      second_topics =
        second()
        |> Enum.map(&topic_fixture/1)

      %{topics: topics} = Keywords.match(first_topics, second_topics)

      IO.puts("""
      There were #{Enum.count(first())} topics in the first epoch.
      There were #{Enum.count(second())} topics in the second epoch.
      There are #{Enum.count(topics)} topics remaining
      """)

      assert Enum.count(topics) == 8
    end

    test "limited case" do
      first = first() |> Enum.map(&topic_fixture/1) |> Enum.slice(1..5)
      second = second() |> Enum.map(&topic_fixture/1) |> Enum.slice(1..5)

      %{topics: topics} = Keywords.match(first, second)

      assert Enum.count(topics) == 5
    end
  end

  def first() do
    [
      %{
        keywords: [
          %{"keyword" => "bathtub cleaning", "probability" => 0.6341258},
          %{"keyword" => "cleaning adventure", "probability" => 0.59667534},
          %{"keyword" => "conquer bathtub", "probability" => 0.5121193},
          %{"keyword" => "cleaning", "probability" => 0.50936484},
          %{"keyword" => "cleaning mission", "probability" => 0.4951586},
          %{"keyword" => "cleaning solutions", "probability" => 0.4861757},
          %{"keyword" => "tub relax", "probability" => 0.48572457},
          %{"keyword" => "scrubbing toothbrush", "probability" => 0.47676772},
          %{"keyword" => "cleaning supplies", "probability" => 0.40605402},
          %{"keyword" => "bathroom", "probability" => 0.39413086}
        ],
        topic_model_id: 0
      },
      %{
        keywords: [
          %{"keyword" => "scrub sink", "probability" => 0.6996696},
          %{"keyword" => "wipe sink", "probability" => 0.64398813},
          %{"keyword" => "sink help", "probability" => 0.5734906},
          %{"keyword" => "sink surface", "probability" => 0.53808343},
          %{"keyword" => "surface sink", "probability" => 0.5332494},
          %{"keyword" => "sink dry", "probability" => 0.5306609},
          %{"keyword" => "need cleaning", "probability" => 0.50523365},
          %{"keyword" => "remove cleaner", "probability" => 0.49426085},
          %{"keyword" => "scrub brush", "probability" => 0.48412168},
          %{"keyword" => "cleaner soap", "probability" => 0.47029287}
        ],
        topic_model_id: 1
      },
      %{
        keywords: [
          %{"keyword" => "clean sink", "probability" => 0.61435604},
          %{"keyword" => "sink hygienic", "probability" => 0.56863165},
          %{"keyword" => "sink looks", "probability" => 0.56515634},
          %{"keyword" => "sparkling sink", "probability" => 0.5618018},
          %{"keyword" => "better sink", "probability" => 0.5319928},
          %{"keyword" => "satisfying clean", "probability" => 0.47858825},
          %{"keyword" => "sink", "probability" => 0.47816288},
          %{"keyword" => "sink let", "probability" => 0.4701188},
          %{"keyword" => "clean sparkling", "probability" => 0.4391232},
          %{"keyword" => "bathtub sparkle", "probability" => 0.4198135}
        ],
        topic_model_id: 2
      },
      %{
        keywords: [
          %{"keyword" => "waste milk", "probability" => 0.6086783},
          %{"keyword" => "acid milk", "probability" => 0.5863774},
          %{"keyword" => "milk naturally", "probability" => 0.5685866},
          %{"keyword" => "trick milk", "probability" => 0.53608716},
          %{"keyword" => "milk", "probability" => 0.5308988},
          %{"keyword" => "lactic acid", "probability" => 0.49852586},
          %{"keyword" => "milk floor", "probability" => 0.47088176},
          %{"keyword" => "milk honest", "probability" => 0.4623834},
          %{"keyword" => "milk sounds", "probability" => 0.4582525},
          %{"keyword" => "breaks stains", "probability" => 0.44087112}
        ],
        topic_model_id: 3
      },
      %{
        keywords: [
          %{"keyword" => "mustard works", "probability" => 0.65271926},
          %{"keyword" => "ketchup mustard", "probability" => 0.61473036},
          %{"keyword" => "vinegar mustard", "probability" => 0.5492809},
          %{"keyword" => "ketchup", "probability" => 0.54338783},
          %{"keyword" => "hack ketchup", "probability" => 0.54324937},
          %{"keyword" => "mustard cuts", "probability" => 0.5380056},
          %{"keyword" => "mixture ketchup", "probability" => 0.527501},
          %{"keyword" => "grime ketchup", "probability" => 0.49958187},
          %{"keyword" => "mustard", "probability" => 0.4772008},
          %{"keyword" => "secret cleaning", "probability" => 0.44034266}
        ],
        topic_model_id: 4
      },
      %{
        keywords: [
          %{"keyword" => "brush spaghetti", "probability" => 0.63036376},
          %{"keyword" => "spaghetti scrub", "probability" => 0.61729586},
          %{"keyword" => "using spaghetti", "probability" => 0.55188525},
          %{"keyword" => "massage floors", "probability" => 0.5316161},
          %{"keyword" => "cleaning", "probability" => 0.5169737},
          %{"keyword" => "creative cleaning", "probability" => 0.51216745},
          %{"keyword" => "spaghetti just", "probability" => 0.5070564},
          %{"keyword" => "cleaning techniques", "probability" => 0.48543635},
          %{"keyword" => "scrub brush", "probability" => 0.48342696},
          %{"keyword" => "proper cleaning", "probability" => 0.48328942}
        ],
        topic_model_id: 5
      },
      %{
        keywords: [
          %{"keyword" => "cleaned floor", "probability" => 0.55914533},
          %{"keyword" => "floor cleaner", "probability" => 0.5579074},
          %{"keyword" => "cleaned bathtub", "probability" => 0.5016895},
          %{"keyword" => "floor mop", "probability" => 0.48992944},
          %{"keyword" => "cleaner boring", "probability" => 0.48692486},
          %{"keyword" => "mop floor", "probability" => 0.4834715},
          %{"keyword" => "bathtub yeah", "probability" => 0.44976136},
          %{"keyword" => "cleaner", "probability" => 0.39888927},
          %{"keyword" => "mop", "probability" => 0.397649},
          %{"keyword" => "hey cleaned", "probability" => 0.3898036}
        ],
        topic_model_id: 6
      },
      %{
        keywords: [
          %{"keyword" => "cleaning", "probability" => 0.529143},
          %{"keyword" => "thorough cleaning", "probability" => 0.528486},
          %{"keyword" => "time cleaning", "probability" => 0.52521235},
          %{"keyword" => "cleaning specific", "probability" => 0.51569927},
          %{"keyword" => "scrub toothbrush", "probability" => 0.4918689},
          %{"keyword" => "cleaning think", "probability" => 0.45117718},
          %{"keyword" => "elbow grease", "probability" => 0.4241144},
          %{"keyword" => "toothbrush shines", "probability" => 0.39530754},
          %{"keyword" => "toothbrush", "probability" => 0.34154588},
          %{"keyword" => "scrub", "probability" => 0.33318907}
        ],
        topic_model_id: 7
      },
      %{
        keywords: [
          %{"keyword" => "scrubbing stains", "probability" => 0.6889372},
          %{"keyword" => "floor cleaner", "probability" => 0.64470845},
          %{"keyword" => "cleaning", "probability" => 0.5996225},
          %{"keyword" => "cleaner thank", "probability" => 0.5735171},
          %{"keyword" => "let cleaner", "probability" => 0.56712174},
          %{"keyword" => "cleaning planning", "probability" => 0.5649775},
          %{"keyword" => "cleaner sit", "probability" => 0.5598433},
          %{"keyword" => "cleaner", "probability" => 0.54501367},
          %{"keyword" => "stubborn stains", "probability" => 0.5396198},
          %{"keyword" => "stains great", "probability" => 0.5349237}
        ],
        topic_model_id: 8
      },
      %{
        keywords: [
          %{"keyword" => "pixie dust", "probability" => 0.57288986},
          %{"keyword" => "unicorn tears", "probability" => 0.5268818},
          %{"keyword" => "tears pixie", "probability" => 0.47129288},
          %{"keyword" => "enchanted pixie", "probability" => 0.44975084},
          %{"keyword" => "tears enchanted", "probability" => 0.4034657},
          %{"keyword" => "dust huh", "probability" => 0.39137545},
          %{"keyword" => "pixie", "probability" => 0.38562602},
          %{"keyword" => "organic unicorn", "probability" => 0.3846134},
          %{"keyword" => "power unicorn", "probability" => 0.36946088},
          %{"keyword" => "dust", "probability" => 0.3653178}
        ],
        topic_model_id: 9
      },
      %{
        keywords: [
          %{"keyword" => "clear sink", "probability" => 0.5893942},
          %{"keyword" => "clear dishes", "probability" => 0.5473614},
          %{"keyword" => "remove sink", "probability" => 0.52840567},
          %{"keyword" => "sink apply", "probability" => 0.5157387},
          %{"keyword" => "wet sink", "probability" => 0.5103272},
          %{"keyword" => "sink", "probability" => 0.47266948},
          %{"keyword" => "sink good", "probability" => 0.46636987},
          %{"keyword" => "cleaner directly", "probability" => 0.4483204},
          %{"keyword" => "supplies clear", "probability" => 0.4312837},
          %{"keyword" => "sink wet", "probability" => 0.4288413}
        ],
        topic_model_id: 10
      },
      %{
        keywords: [
          %{"keyword" => "sink scrubbing", "probability" => 0.74565315},
          %{"keyword" => "scrub thoroughly", "probability" => 0.6958682},
          %{"keyword" => "rinse sink", "probability" => 0.6819507},
          %{"keyword" => "scrubbing alright", "probability" => 0.66075945},
          %{"keyword" => "clean sink", "probability" => 0.6477481},
          %{"keyword" => "start scrubbing", "probability" => 0.627069},
          %{"keyword" => "scrubbing", "probability" => 0.62191296},
          %{"keyword" => "specific cleaning", "probability" => 0.6186001},
          %{"keyword" => "cleaning", "probability" => 0.6133715},
          %{"keyword" => "use clean", "probability" => 0.5969031}
        ],
        topic_model_id: 11
      },
      %{
        keywords: [
          %{"keyword" => "got", "probability" => 0.6358658},
          %{"keyword" => "okay got", "probability" => 0.6313292},
          %{"keyword" => "got got", "probability" => 0.6167079},
          %{"keyword" => "okay", "probability" => 0.49623913},
          %{"keyword" => "", "probability" => 0.34581763},
          %{"keyword" => "", "probability" => 0.34581763},
          %{"keyword" => "", "probability" => 0.34581763},
          %{"keyword" => "", "probability" => 0.34581763},
          %{"keyword" => "", "probability" => 0.34581763},
          %{"keyword" => "", "probability" => 0.34581763}
        ],
        topic_model_id: 12
      }
    ]
  end

  def second() do
    [
      %{
        keywords: [
          %{"keyword" => "cleaning toilet", "probability" => 0.69154394},
          %{"keyword" => "tablets toilet", "probability" => 0.57916737},
          %{"keyword" => "seeds toilet", "probability" => 0.5672115},
          %{"keyword" => "make cleaning", "probability" => 0.560537},
          %{"keyword" => "friendly cleaning", "probability" => 0.54845434},
          %{"keyword" => "toilet grime", "probability" => 0.5278518},
          %{"keyword" => "cleaning antacid", "probability" => 0.5271593},
          %{"keyword" => "does cleaning", "probability" => 0.52168965},
          %{"keyword" => "cleaning", "probability" => 0.51907945},
          %{"keyword" => "handle toilet", "probability" => 0.51608133}
        ],
        topic_model_id: -1
      },
      %{
        keywords: [
          %{"keyword" => "specific cleaning", "probability" => 0.67321837},
          %{"keyword" => "cleaning specific", "probability" => 0.66339314},
          %{"keyword" => "sink scrubbing", "probability" => 0.606742},
          %{"keyword" => "cleaning", "probability" => 0.58688015},
          %{"keyword" => "cleaning preparing", "probability" => 0.5867777},
          %{"keyword" => "cleaner directly", "probability" => 0.58307815},
          %{"keyword" => "time cleaning", "probability" => 0.5744021},
          %{"keyword" => "use clean", "probability" => 0.57311255},
          %{"keyword" => "scrub thoroughly", "probability" => 0.5716615},
          %{"keyword" => "thorough cleaning", "probability" => 0.56721294}
        ],
        topic_model_id: 0
      },
      %{
        keywords: [
          %{"keyword" => "bathtub cleaning", "probability" => 0.6182091},
          %{"keyword" => "bathroom cleaning", "probability" => 0.61122656},
          %{"keyword" => "cleaning adventure", "probability" => 0.53864026},
          %{"keyword" => "tub relax", "probability" => 0.5041081},
          %{"keyword" => "conquer bathtub", "probability" => 0.49618083},
          %{"keyword" => "cleaning mission", "probability" => 0.48758462},
          %{"keyword" => "cleaning", "probability" => 0.46893758},
          %{"keyword" => "cleaning solutions", "probability" => 0.46000427},
          %{"keyword" => "sparkling toilet", "probability" => 0.41110045},
          %{"keyword" => "tub", "probability" => 0.40560132}
        ],
        topic_model_id: 1
      },
      %{
        keywords: [
          %{"keyword" => "double cleaning", "probability" => 0.62864363},
          %{"keyword" => "cleaning techniques", "probability" => 0.582216},
          %{"keyword" => "tips cleaning", "probability" => 0.5678879},
          %{"keyword" => "speed cleaning", "probability" => 0.5648751},
          %{"keyword" => "creative cleaning", "probability" => 0.56375855},
          %{"keyword" => "cleaning", "probability" => 0.5637276},
          %{"keyword" => "scrubbing toothbrush", "probability" => 0.55855143},
          %{"keyword" => "power cleaning", "probability" => 0.5240711},
          %{"keyword" => "cleaning power", "probability" => 0.49852383},
          %{"keyword" => "grab toothbrush", "probability" => 0.48372585}
        ],
        topic_model_id: 2
      },
      %{
        keywords: [
          %{"keyword" => "chocolate shower", "probability" => 0.61832863},
          %{"keyword" => "scented shower", "probability" => 0.5642697},
          %{"keyword" => "squirrels bathroom", "probability" => 0.5277442},
          %{"keyword" => "peanut scented", "probability" => 0.5184599},
          %{"keyword" => "cleanser peanut", "probability" => 0.51766616},
          %{"keyword" => "skin shower", "probability" => 0.5100272},
          %{"keyword" => "shower", "probability" => 0.50441504},
          %{"keyword" => "shower new", "probability" => 0.47483665},
          %{"keyword" => "oils peanut", "probability" => 0.4746549},
          %{"keyword" => "shower yeah", "probability" => 0.46833783}
        ],
        topic_model_id: 3
      },
      %{
        keywords: [
          %{"keyword" => "clean toilet", "probability" => 0.6659377},
          %{"keyword" => "clean floors", "probability" => 0.6435537},
          %{"keyword" => "cleaned floor", "probability" => 0.6324827},
          %{"keyword" => "cleaned bathtub", "probability" => 0.5921071},
          %{"keyword" => "know clean", "probability" => 0.5435134},
          %{"keyword" => "toilet gentle", "probability" => 0.5250102},
          %{"keyword" => "toilet properly", "probability" => 0.49761373},
          %{"keyword" => "hey cleaned", "probability" => 0.4866783},
          %{"keyword" => "giving toilet", "probability" => 0.48646224},
          %{"keyword" => "clean", "probability" => 0.47657418}
        ],
        topic_model_id: 4
      },
      %{
        keywords: [
          %{"keyword" => "clean sink", "probability" => 0.61435604},
          %{"keyword" => "sink hygienic", "probability" => 0.56863165},
          %{"keyword" => "sink looks", "probability" => 0.56515634},
          %{"keyword" => "sparkling sink", "probability" => 0.56180173},
          %{"keyword" => "better sink", "probability" => 0.5319927},
          %{"keyword" => "satisfying clean", "probability" => 0.47858825},
          %{"keyword" => "sink", "probability" => 0.4781629},
          %{"keyword" => "sink let", "probability" => 0.47011876},
          %{"keyword" => "clean sparkling", "probability" => 0.4391232},
          %{"keyword" => "bathtub sparkle", "probability" => 0.4198135}
        ],
        topic_model_id: 5
      },
      %{
        keywords: [
          %{"keyword" => "floor cleaner", "probability" => 0.69634616},
          %{"keyword" => "cleaning routine", "probability" => 0.65719664},
          %{"keyword" => "cleaner routine", "probability" => 0.630338},
          %{"keyword" => "massage floors", "probability" => 0.62270665},
          %{"keyword" => "sweeping floor", "probability" => 0.61003315},
          %{"keyword" => "cleaning", "probability" => 0.58539736},
          %{"keyword" => "whimsy cleaning", "probability" => 0.5698563},
          %{"keyword" => "mop floor", "probability" => 0.56921625},
          %{"keyword" => "turn cleaning", "probability" => 0.5646954},
          %{"keyword" => "proper cleaning", "probability" => 0.5626953}
        ],
        topic_model_id: 6
      },
      %{
        keywords: [
          %{"keyword" => "whipped cream", "probability" => 0.62782633},
          %{"keyword" => "cream cleaning", "probability" => 0.5953251},
          %{"keyword" => "cream clean", "probability" => 0.5917742},
          %{"keyword" => "waste milk", "probability" => 0.5206408},
          %{"keyword" => "using whipped", "probability" => 0.51030904},
          %{"keyword" => "floor whipped", "probability" => 0.5096816},
          %{"keyword" => "milk floor", "probability" => 0.50648755},
          %{"keyword" => "cream dessert", "probability" => 0.50183576},
          %{"keyword" => "cream", "probability" => 0.49050784},
          %{"keyword" => "trick milk", "probability" => 0.4799421}
        ],
        topic_model_id: 7
      },
      %{
        keywords: [
          %{"keyword" => "toilet cleaning", "probability" => 0.69349194},
          %{"keyword" => "shower cleaner", "probability" => 0.6279439},
          %{"keyword" => "bowl cleaner", "probability" => 0.61090136},
          %{"keyword" => "scrub brush", "probability" => 0.60657305},
          %{"keyword" => "cleaner scrub", "probability" => 0.60354257},
          %{"keyword" => "cleaning", "probability" => 0.6030811},
          %{"keyword" => "cleaner brush", "probability" => 0.6001368},
          %{"keyword" => "floor cleaner", "probability" => 0.5964775},
          %{"keyword" => "cleaner", "probability" => 0.52925533},
          %{"keyword" => "methods toilet", "probability" => 0.5073811}
        ],
        topic_model_id: 8
      },
      %{
        keywords: [
          %{"keyword" => "mustard works", "probability" => 0.68792605},
          %{"keyword" => "ketchup mustard", "probability" => 0.68059707},
          %{"keyword" => "mixture ketchup", "probability" => 0.6060009},
          %{"keyword" => "vinegar mustard", "probability" => 0.60565317},
          %{"keyword" => "ketchup", "probability" => 0.5982282},
          %{"keyword" => "hack ketchup", "probability" => 0.5821608},
          %{"keyword" => "mustard cuts", "probability" => 0.57763696},
          %{"keyword" => "grime ketchup", "probability" => 0.56326437},
          %{"keyword" => "mustard", "probability" => 0.52895516},
          %{"keyword" => "secret cleaning", "probability" => 0.49773055}
        ],
        topic_model_id: 9
      },
      %{
        keywords: [
          %{"keyword" => "loofah sponge", "probability" => 0.52595294},
          %{"keyword" => "loofah natural", "probability" => 0.48655602},
          %{"keyword" => "exfoliating", "probability" => 0.44285825},
          %{"keyword" => "sponge", "probability" => 0.42285162},
          %{"keyword" => "exfoliating fibers", "probability" => 0.41849288},
          %{"keyword" => "creamy texture", "probability" => 0.41802335},
          %{"keyword" => "workout loofah", "probability" => 0.4141415},
          %{"keyword" => "natural exfoliating", "probability" => 0.41286963},
          %{"keyword" => "sponge isn", "probability" => 0.40580803},
          %{"keyword" => "reach crevices", "probability" => 0.39995152}
        ],
        topic_model_id: 10
      },
      %{
        keywords: [
          %{"keyword" => "rinse sink", "probability" => 0.7417896},
          %{"keyword" => "scrub sink", "probability" => 0.7042348},
          %{"keyword" => "sink help", "probability" => 0.61204267},
          %{"keyword" => "wet sink", "probability" => 0.57301426},
          %{"keyword" => "surface sink", "probability" => 0.5705355},
          %{"keyword" => "sink wet", "probability" => 0.544368},
          %{"keyword" => "gently scrub", "probability" => 0.5192243},
          %{"keyword" => "apply cleaner", "probability" => 0.518379},
          %{"keyword" => "absolutely rinse", "probability" => 0.4958886},
          %{"keyword" => "sink", "probability" => 0.49121183}
        ],
        topic_model_id: 11
      },
      %{
        keywords: [
          %{"keyword" => "scrubbing stains", "probability" => 0.6210576},
          %{"keyword" => "cleaner thank", "probability" => 0.52425075},
          %{"keyword" => "cleaning", "probability" => 0.5200338},
          %{"keyword" => "let cleaner", "probability" => 0.5164817},
          %{"keyword" => "floor cleaner", "probability" => 0.5093927},
          %{"keyword" => "stains great", "probability" => 0.50373197},
          %{"keyword" => "cleaner sit", "probability" => 0.5028236},
          %{"keyword" => "stubborn stains", "probability" => 0.49180362},
          %{"keyword" => "cleaner", "probability" => 0.48335677},
          %{"keyword" => "cleaning planning", "probability" => 0.48156598}
        ],
        topic_model_id: 12
      },
      %{
        keywords: [
          %{"keyword" => "got", "probability" => 0.6358658},
          %{"keyword" => "okay got", "probability" => 0.6313292},
          %{"keyword" => "got got", "probability" => 0.6167079},
          %{"keyword" => "okay", "probability" => 0.49623913},
          %{"keyword" => "", "probability" => 0.34581771},
          %{"keyword" => "", "probability" => 0.34581771},
          %{"keyword" => "", "probability" => 0.34581771},
          %{"keyword" => "", "probability" => 0.34581771},
          %{"keyword" => "", "probability" => 0.34581771},
          %{"keyword" => "", "probability" => 0.34581771}
        ],
        topic_model_id: 13
      },
      %{
        keywords: [
          %{"keyword" => "dirty sink", "probability" => 0.7021073},
          %{"keyword" => "wipe sink", "probability" => 0.7004878},
          %{"keyword" => "need cleaning", "probability" => 0.6080897},
          %{"keyword" => "sink surface", "probability" => 0.5718616},
          %{"keyword" => "sink dry", "probability" => 0.56371415},
          %{"keyword" => "cleaning", "probability" => 0.5252907},
          %{"keyword" => "sink", "probability" => 0.5156544},
          %{"keyword" => "cleaning dry", "probability" => 0.50245994},
          %{"keyword" => "scrub brush", "probability" => 0.49724096},
          %{"keyword" => "sink desperate", "probability" => 0.49425477}
        ],
        topic_model_id: 14
      },
      %{
        keywords: [
          %{"keyword" => "pixie dust", "probability" => 0.57288986},
          %{"keyword" => "unicorn tears", "probability" => 0.5268818},
          %{"keyword" => "tears pixie", "probability" => 0.47129288},
          %{"keyword" => "enchanted pixie", "probability" => 0.44975084},
          %{"keyword" => "tears enchanted", "probability" => 0.4034657},
          %{"keyword" => "dust huh", "probability" => 0.39137545},
          %{"keyword" => "pixie", "probability" => 0.38562602},
          %{"keyword" => "organic unicorn", "probability" => 0.3846134},
          %{"keyword" => "power unicorn", "probability" => 0.36946088},
          %{"keyword" => "dust", "probability" => 0.3653178}
        ],
        topic_model_id: 15
      },
      %{
        keywords: [
          %{"keyword" => "floors feelings", "probability" => 0.6300936},
          %{"keyword" => "excitement suit", "probability" => 0.4961841},
          %{"keyword" => "remember floors", "probability" => 0.48510352},
          %{"keyword" => "floors", "probability" => 0.4801731},
          %{"keyword" => "excitement sweet", "probability" => 0.44986385},
          %{"keyword" => "party floor", "probability" => 0.43700424},
          %{"keyword" => "excitement", "probability" => 0.4315012},
          %{"keyword" => "toilets", "probability" => 0.43031883},
          %{"keyword" => "remember toilets", "probability" => 0.41837123},
          %{"keyword" => "little excitement", "probability" => 0.41415465}
        ],
        topic_model_id: 16
      },
      %{
        keywords: [
          %{"keyword" => "mayonnaise toilet", "probability" => 0.7458379},
          %{"keyword" => "mayo toilet", "probability" => 0.7174503},
          %{"keyword" => "bowl polish", "probability" => 0.62830055},
          %{"keyword" => "toilet bowl", "probability" => 0.6152599},
          %{"keyword" => "porcelain bowl", "probability" => 0.61018527},
          %{"keyword" => "using mayonnaise", "probability" => 0.59805727},
          %{"keyword" => "toilet glossy", "probability" => 0.5544933},
          %{"keyword" => "oils mayo", "probability" => 0.5507549},
          %{"keyword" => "mayonnaise", "probability" => 0.547457},
          %{"keyword" => "mayo", "probability" => 0.5155859}
        ],
        topic_model_id: 17
      },
      %{
        keywords: [
          %{"keyword" => "magical potion", "probability" => 0.57352424},
          %{"keyword" => "potion", "probability" => 0.54445183},
          %{"keyword" => "remove stains", "probability" => 0.52243185},
          %{"keyword" => "breaks stains", "probability" => 0.5210906},
          %{"keyword" => "stains spills", "probability" => 0.49027842},
          %{"keyword" => "potion online", "probability" => 0.48480016},
          %{"keyword" => "potion sounds", "probability" => 0.46553993},
          %{"keyword" => "stains", "probability" => 0.4625353},
          %{"keyword" => "stains just", "probability" => 0.45990717},
          %{"keyword" => "acid milk", "probability" => 0.4347621}
        ],
        topic_model_id: 18
      },
      %{
        keywords: [
          %{"keyword" => "singing frogs", "probability" => 0.609516},
          %{"keyword" => "frogs singing", "probability" => 0.5925427},
          %{"keyword" => "away frogs", "probability" => 0.5638236},
          %{"keyword" => "frogs harmonious", "probability" => 0.5575019},
          %{"keyword" => "frogs", "probability" => 0.5154263},
          %{"keyword" => "frog good", "probability" => 0.4999822},
          %{"keyword" => "frog", "probability" => 0.47669986},
          %{"keyword" => "seen frog", "probability" => 0.45635265},
          %{"keyword" => "dirt chittering", "probability" => 0.45279613},
          %{"keyword" => "paws scrub", "probability" => 0.41407514}
        ],
        topic_model_id: 19
      },
      %{
        keywords: [
          %{"keyword" => "socks dirty", "probability" => 0.7027516},
          %{"keyword" => "ninja socks", "probability" => 0.67707753},
          %{"keyword" => "wear socks", "probability" => 0.6487179},
          %{"keyword" => "socks wear", "probability" => 0.64600813},
          %{"keyword" => "socks hands", "probability" => 0.6377685},
          %{"keyword" => "old socks", "probability" => 0.6181822},
          %{"keyword" => "socks sounds", "probability" => 0.59281987},
          %{"keyword" => "cleaning gloves", "probability" => 0.59189916},
          %{"keyword" => "socks", "probability" => 0.58890486},
          %{"keyword" => "ninja cleaning", "probability" => 0.526647}
        ],
        topic_model_id: 20
      },
      %{
        keywords: [
          %{"keyword" => "reading cleaning", "probability" => 0.6593273},
          %{"keyword" => "cleaning reading", "probability" => 0.64446485},
          %{"keyword" => "vacuum clean", "probability" => 0.5309534},
          %{"keyword" => "ink floor", "probability" => 0.5291069},
          %{"keyword" => "cleaning accidentally", "probability" => 0.5043806},
          %{"keyword" => "cleaning", "probability" => 0.45998526},
          %{"keyword" => "newspapers mop", "probability" => 0.43260354},
          %{"keyword" => "smear ink", "probability" => 0.42251956},
          %{"keyword" => "mop floor", "probability" => 0.4205572},
          %{"keyword" => "like cleaning", "probability" => 0.4108179}
        ],
        topic_model_id: 21
      }
    ]
  end
end
