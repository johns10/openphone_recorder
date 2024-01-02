defmodule Discussit.Topics.Summarizer do
  alias Discussit.Topics
  alias Discussit.Topics.Topic
  alias Discussit.Statements
  alias Discussit.Usages.ResponseHandlers
  alias Discussit.StatusAgent

  def apply(topic_id, account_id) do
    model = "gpt-3.5-turbo"
    opts = [max_tokens: 110, temperature: 0, model: model, account_id: account_id]

    with %Topic{} = topic = Topics.get_topic!(topic_id),
         name = StatusAgent.topic_summarizer_name(topic),
         {:ok, name} <- StatusAgent.new(name),
         {:ok, :started} <- StatusAgent.set(name, :started),
         content <- get_content(topic.id),
         messages = [%{role: :user, content: prompt(topic, content)}],
         {:ok, response} <- ExOpenAI.Chat.create_chat_completion(messages, model, opts),
         {:ok, _usage} <- ResponseHandlers.chat_completion(response, opts),
         %{choices: [%{message: %{content: content}}]} <- response,
         [title, description] <- String.split(content, "|"),
         attrs = %{model_title: title, model_description: description},
         {:ok, topic} <- Topics.update_topic(topic, attrs),
         {:ok, :not_started} <- StatusAgent.set(name, :finished) do
      {:ok, topic}
    end
  end

  defp get_content(topic_id) do
    Statements.list_statements(
      filters: [cumulative_content_length: 3000, topic_id: topic_id],
      order_by: [representative: :desc]
    )
    |> Enum.map(& &1.content)
    |> Enum.join(" ")
  end

  defp prompt(%Topic{keywords: keywords}, content) do
    """
    I have a topic that contains the following documents:
    #{content}
    The topic is described by the following keywords:
    #{Enum.map(keywords, fn %{"keyword" => keyword} -> keyword end) |> Enum.join(", ")}

    Based on the information above:
    Extract a short but highly descriptive topic label of at most 5 words.
    Extract a short but highly descriptive topic description of at most 100 words
    Return the result in the following format
    <topic label> | <topic description>
    """
  end
end
