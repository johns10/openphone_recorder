defmodule Discussit.Topics.Keywords do
  alias Discussit.Topics
  @doc "Takes a list of topics, and a list of model attrs, and updates matching topics"
  def match(topics, new_topics) do
    initial_acc = %{new_topics: new_topics, topics: []}

    topics
    |> Enum.reduce(initial_acc, fn topic, %{new_topics: new_topics} = acc ->
      %{score: best_score, id: topic_id} =
        match =
        topic_scores(topic, new_topics)
        |> Enum.max(fn score1, score2 -> score1.score >= score2.score end)

      case best_score do
        score when score >= 0.80 ->
          Topics.update_topic(match, %{from_topic_id: topic_id})
          remove_model_attrs(acc, topic_id)

        _ ->
          %{acc | topics: [topic | acc.topics]}
      end
    end)
  end

  def to_string(%{keywords: [%{"keyword" => _} | _] = keywords} = _topic),
    do: Enum.map(keywords, fn %{"keyword" => keyword} -> keyword end) |> Enum.join(", ")

  defp remove_model_attrs(%{new_topics: new_topics} = state, topic_id) do
    new_topics = new_topics |> Enum.filter(fn %{id: id} -> id != topic_id end)

    %{state | new_topics: new_topics}
  end

  @spec topic_scores(%{:keywords => any(), optional(any()) => any()}, any()) :: list()
  def topic_scores(one, new_topics) do
    Enum.map(new_topics, fn two ->
      Map.put(two, :score, calculate_score(one, two))
    end)
  end

  def calculate_score(%{keywords: kw_one}, %{keywords: kw_two}) do
    score = sum_score(kw_one, kw_two) + sum_score(kw_two, kw_one)
    total = sum_total(kw_one) + sum_total(kw_two)
    score / total
  end

  defp sum_total(keywords),
    do:
      Enum.reduce(keywords, 0, fn
        %{probability: p}, acc -> acc + p
        %{"probability" => p}, acc -> acc + p
      end)

  defp sum_score(one, two) do
    Enum.reduce(one, 0, fn
      %{keyword: keyword, probability: probability}, acc ->
        find_matching_keyword(acc, two, keyword, probability)

      %{"keyword" => keyword, "probability" => probability}, acc ->
        find_matching_keyword(acc, two, keyword, probability)
    end)
  end

  defp find_matching_keyword(acc, two, match_kw, probability) do
    two
    |> Enum.find(fn
      %{"keyword" => keyword} -> match_kw == keyword
      %{keyword: keyword} -> match_kw == keyword
    end)
    |> case do
      %{} -> acc + probability
      nil -> acc
    end
  end
end
