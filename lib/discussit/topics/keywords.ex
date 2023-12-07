defmodule Discussit.Topics.Keywords do
  alias Discussit.Topics
  @doc "Takes a list of topics, and a list of model attrs, and updates matching topics"
  def match(topics, raw_models_attrs) do
    initial_acc = %{models_attrs: cast_models_attrs(raw_models_attrs), topics: []}

    topics
    |> Enum.reduce(initial_acc, fn topic, %{models_attrs: models_attrs} = acc ->
      %{score: best_score, model_id: model_id} =
        best_match =
        topic_scores(topic, models_attrs)
        |> Enum.max(fn score1, score2 -> score1.score >= score2.score end)

      case best_score do
        score when score >= 0.80 ->
          Topics.update_topic(topic, best_match)
          remove_model_attrs(acc, model_id)

        _score ->
          %{acc | topics: [topic | acc.topics]}
      end
    end)
  end

  defp remove_model_attrs(%{models_attrs: models_attrs} = state, model_id) do
    models_attrs = models_attrs |> Enum.filter(fn %{model_id: id} -> id != model_id end)
    %{state | models_attrs: models_attrs}
  end

  defp topic_scores(%{keywords: t_kw} = topic, models_attrs) do
    Enum.map(models_attrs, fn %{keywords: m_kw} = model_attrs ->
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
end
