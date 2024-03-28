defmodule Discussit.Tokens do
  alias Discussit.Statements.Statement
  alias Discussit.Summaries.Summary
  alias Discussit.Tokens.Stopwords

  defp default_model(), do: Discussit.Models.Model.default_llm_id()

  def max_text_output_count(opts \\ []) do
    percentage_reduction = Keyword.get(opts, :percentage_reduction, nil)
    fixed_reduction = Keyword.get(opts, :fixed_reduction, nil)
    model = Keyword.get(opts, :model, default_model())
    max_token_count = Keyword.get(opts, :max_tokens, max_output_count(model))
    prompt_count = Keyword.get(opts, :prompt) |> count()
    reduction_mode = Keyword.get(opts, :reduction_mode)

    result =
      case reduction_mode do
        :fixed ->
          fixed_reduction

        :percentage ->
          ((max_token_count - prompt_count) / (1 / percentage_reduction + 1))
          |> floor()

        nil ->
          default_model() |> max_output_count()
      end

    Keyword.get(opts, :max_text_output_count, result)
  end

  def max_output_count("gpt-3.5-turbo"), do: 4_096

  def max_context_count(opts \\ []) do
    result = opts |> Keyword.get(:model, default_model()) |> max_input_count()
    Keyword.get(opts, :max_context_count, result)
  end

  def max_input_count("gpt-3.5-turbo"), do: 16_385

  def count(statements) when is_list(statements),
    do: statements |> Enum.reduce(0, fn statement, acc -> acc + count(statement) end)

  def count([%Statement{} | _] = statements),
    do: Enum.reduce(statements, 0, fn statement, acc -> acc + count(statement) end)

  def count([%Summary{} | _] = statements),
    do: Enum.reduce(statements, 0, fn statement, acc -> acc + count(statement) end)

  def count(%Statement{} = statement), do: statement |> Statement.render_for_prompt() |> count()

  def count(%Summary{} = summary), do: summary |> Summary.render_for_prompt() |> count()

  def count(string), do: Gpt3Tokenizer.token_count(string)

  def all_stopwords?(text, opts \\ [])
  def all_stopwords?(nil, _opts), do: true
  def all_stopwords?("", _opts), do: true

  def all_stopwords?(text, _opts) do
    text
    |> Gpt3Tokenizer.encode()
    |> Enum.map(&(&1 in Stopwords.list(:english)))
    |> Enum.reduce_while(true, fn stopword?, _acc ->
      if stopword?, do: {:cont, true}, else: {:halt, false}
    end)
  end
end
