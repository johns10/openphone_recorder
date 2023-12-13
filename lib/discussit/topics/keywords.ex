defmodule Discussit.Topics.Keywords do
  alias Discussit.Topics
  @doc "Takes a list of topics, and a list of model attrs, and updates matching topics"
  def match(topics, new_topics) do
    initial_acc = %{new_topics: new_topics, topics: []}

    topics
    |> Enum.reduce(initial_acc, fn topic, %{new_topics: new_topics} = acc ->
      %{score: best_score, topic_model_id: topic_model_id, id: topic_id} =
        topic_scores(topic, new_topics)
        |> Enum.max(fn score1, score2 -> score1.score >= score2.score end)

      case best_score do
        score when score >= 0.80 ->
          Topics.update_topic(topic, %{from_topic_id: topic_id})
          remove_model_attrs(acc, topic_id)

        score ->
          IO.puts("Remaining: #{Enum.count(acc.topics)}, #{score}")
          %{acc | topics: [topic | acc.topics]}
      end
    end)
  end

  defp remove_model_attrs(%{new_topics: new_topics} = state, topic_id) do
    new_topics = new_topics |> Enum.filter(fn %{id: id} -> id != topic_id end)

    %{state | new_topics: new_topics}
  end

  defp topic_scores(%{keywords: t_kw} = topic, new_topics) do
    Enum.map(new_topics, fn %{keywords: m_kw} = model_attrs ->
      score = sum_score(t_kw, m_kw) + sum_score(m_kw, t_kw)
      total = sum_total(topic.keywords) + sum_total(model_attrs.keywords)

      model_attrs
      |> Map.put(:score, score / total)
    end)
  end

  defp sum_total(keywords),
    do:
      Enum.reduce(keywords, 0, fn
        %{probability: p}, acc -> acc + p
      end)

  defp sum_score(one, two) do
    Enum.reduce(one, 0, fn %{keyword: keyword, probability: probability}, acc ->
      case Enum.find(two, &(&1.keyword == keyword)) do
        %{} -> acc + probability
        nil -> acc
      end
    end)
  end
end
