defmodule Discussit.Topics.Keywords do
  alias Discussit.Topics
  @doc "Takes a list of topics, and a list of model attrs, and updates matching topics"
  def match(topics, models_attrs) do
    models_attrs = cast_models_attrs(models_attrs)
    topic_scores = topic_scores(topics, models_attrs)
    model_scores = model_attr_scores(topics, models_attrs)

    init = %{topics: [], topic_scores: topic_scores, model_scores: model_scores}

    topics
    |> Enum.reduce(init, fn topic, acc ->
      topic_scores = topic_scores[topic.id]
      topic_score = Enum.max(topic_scores, fn score1, score2 -> score1.score >= score2.score end)
      %{model_id: model_id} = topic_score
      model_score = model_scores[topic_score.model_id] |> Enum.find(&(&1.topic_id == topic.id))
      model_attrs = Enum.find(models_attrs, &(&1.model_id == topic_score.model_id))

      case calculate_total_score(topic_score, model_score) do
        score when score >= 0.85 ->
          Topics.update_topic(topic, model_attrs)

          remove_model_score(acc, model_id)
          |> remove_topic_score(topic.id)

        _score ->
          %{acc | topics: [topic | acc.topics]}
      end
    end)
  end

  defp remove_model_score(%{model_scores: model_scores} = state, model_id) do
    model_scores = model_scores |> Enum.filter(fn {id, _} -> id == model_id end)
    %{state | model_scores: model_scores}
  end

  defp remove_topic_score(%{topic_scores: topic_scores} = state, topic_id) do
    topic_scores |> Enum.filter(fn {id, _} -> id == topic_id end)
    %{state | topic_scores: topic_scores}
  end

  defp topic_scores(topics, models_attrs) do
    topics
    |> Enum.reduce(%{}, fn topic, acc ->
      row =
        Enum.map(models_attrs, fn model_attrs ->
          cast_score(model_attrs.keywords, topic.keywords)
          |> Map.put(:model_id, model_attrs.model_id)
        end)

      Map.put(acc, topic.id, row)
    end)
  end

  defp model_attr_scores(topics, models_attrs) do
    models_attrs
    |> Enum.reduce(%{}, fn model_attrs, acc ->
      row =
        Enum.map(topics, fn topic ->
          cast_score(topic.keywords, model_attrs.keywords)
          |> Map.put(:topic_id, topic.id)
        end)

      Map.put(acc, model_attrs.model_id, row)
    end)
  end

  defp cast_score(one, two) do
    %{score: sum_score(one, two), total: sum_total(one)}
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

  defp cast_models_attrs(models_attrs) do
    models_attrs
    |> Enum.map(fn %{keywords: keywords} = item ->
      keywords =
        Enum.map(keywords, fn %{"keyword" => k, "probability" => p} ->
          %{keyword: k, probability: p}
        end)

      %{item | keywords: keywords}
    end)
  end

  defp calculate_total_score(one, two) do
    (one.score + two.score) / (one.total + two.total)
  end
end
