defmodule Discussit.Tokens do
  alias Discussit.Statements.Statement
  alias Discussit.Summaries.Summary
  alias Discussit.Tokens.Stopwords

  def max_text_output_count(opts \\ []) do
    percentage_reduction = Keyword.get(opts, :percentage_reduction, nil)
    fixed_reduction = Keyword.get(opts, :fixed_reduction, nil)
    max_token_count = Keyword.get(opts, :max_tokens, 4096)
    prompt_count = Keyword.get(opts, :prompt) |> count()
    reduction_mode = Keyword.get(opts, :reduction_mode, :fixed)

    case reduction_mode do
      :fixed ->
        fixed_reduction

      :percentage ->
        ((max_token_count - prompt_count) / (1 / percentage_reduction + 1))
        |> floor()
    end
  end

  def max_text_count(opts \\ []) do
    max_token_count = Keyword.get(opts, :max_tokens, 4096)
    prompt = Keyword.get(opts, :prompt)
    prompt_count = count(prompt)

    max_token_count - prompt_count
  end

  def max_context_count(opts \\ []) do
    max_token_count = Keyword.get(opts, :max_tokens, 4096)
    prompt = Keyword.get(opts, :prompt)
    prompt_count = count(prompt)

    max_token_count - prompt_count - max_text_output_count(opts)
  end

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
